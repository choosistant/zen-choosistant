import json

from typing import Any, Dict, List
from urllib.parse import urlparse

from label_studio_sdk.project import Project
from zenml.integrations.azure.artifact_stores import AzureArtifactStore
from zenml.integrations.label_studio.annotators import LabelStudioAnnotator
from zenml.integrations.label_studio.steps import (
    LabelStudioDatasetSyncParameters,
)
from zenml.steps import StepContext, step

from choozen.helpers import (
    get_artifact_store,
    get_azure_secret,
    get_label_studio_annotator,
)


def upload_examples_to_artifact_store(
    examples: List[Dict[str, Any]],
    path_prefix: str,
    artifact_store: AzureArtifactStore,
) -> None:
    for example in examples:
        file_path = f"{path_prefix}/{example['id']}.json"
        if not artifact_store.exists(file_path):
            print(f" - Uploading {file_path} to artifact store.")
            with artifact_store.open(file_path, "wb") as f:
                f.write(json.dumps(example).encode("utf-8"))
        else:
            print(f" - File {file_path} already exists. Skipping upload.")


def find_or_create_label_studio_source_storage(
    annotator: LabelStudioAnnotator,
    dataset: Project,
    uri: str,
    params: LabelStudioDatasetSyncParameters,
) -> Dict[str, Any]:
    """Find or create a Label Studio source storage."""
    dataset_id = int(dataset.get_params()["id"])
    title = dataset.get_params()["title"]
    print("Looking for existing source storage in Label Studio.")
    storage_sources = annotator._get_azure_import_storage_sources(dataset_id)
    found_storage_source = None
    for storage_source in storage_sources:
        print(f" - Found storage source: {storage_source}")
        if (
            storage_source.get("container") == uri
            and storage_source.get("prefix") == params.prefix
            and storage_source.get("type") == params.storage_type
            and storage_source.get("title") == title
            and storage_source.get("project") == dataset_id
        ):
            found_storage_source = storage_source
            break

    if not found_storage_source:
        print(" - Source storage not found, creating a new one.")
        found_storage_source = dataset.connect_azure_import_storage(
            container=uri,
            account_name=params.azure_account_name,
            account_key=params.azure_account_key,
            prefix=params.prefix,
            regex_filter=params.regex_filter,
            use_blob_urls=params.use_blob_urls,
            presign=params.presign,
            presign_ttl=params.presign_ttl,
            title=title,
            description=params.description,
        )
    return found_storage_source


@step
def sync_to_label_studio(
    dataset_name: str,
    examples: List[Dict[str, Any]],
    context: StepContext,
) -> None:
    """Upload the data to Label Studio."""

    annotator = get_label_studio_annotator(context)
    artifact_store = get_artifact_store(context)
    azure_secret = get_azure_secret(context)

    label_studio_dir_name = "label-studio-storage"
    label_studio_full_path = f"{artifact_store.path}/{label_studio_dir_name}"

    upload_examples_to_artifact_store(
        examples=examples,
        path_prefix=label_studio_full_path,
        artifact_store=artifact_store,
    )

    sync_params = LabelStudioDatasetSyncParameters(
        storage_type="azure",
        label_config_type="text",
        prefix=label_studio_dir_name,
        use_blob_urls=False,
        blob_account_name=azure_secret.account_name,
        blob_account_key=azure_secret.account_key,
    )

    dataset: Project = annotator.get_dataset(dataset_name=dataset_name)

    base_uri = urlparse(artifact_store.path).netloc

    source_storage = find_or_create_label_studio_source_storage(
        annotator=annotator,
        dataset=dataset,
        uri=base_uri,
        params=sync_params,
    )

    print("Syncing source storage in Label Studio.")

    label_studio_client = annotator._get_client()
    label_studio_client.sync_storage(
        storage_type=source_storage["type"], storage_id=source_storage["id"]
    )


# Create a step
sync_to_label_studio_step = sync_to_label_studio()
