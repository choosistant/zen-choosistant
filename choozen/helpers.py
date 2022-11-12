from zenml.exceptions import StackComponentInterfaceError
from zenml.integrations.azure.artifact_stores import AzureArtifactStore
from zenml.integrations.label_studio.annotators import LabelStudioAnnotator
from zenml.secret.schemas import AzureSecretSchema
from zenml.stack.authentication_mixin import AuthenticationMixin
from zenml.steps import StepContext


def get_azure_secret(context: StepContext) -> AzureSecretSchema:
    artifact_store = context.stack.artifact_store  # type: ignore[union-attr]

    if not isinstance(artifact_store, AuthenticationMixin):
        raise TypeError(
            "The artifact store must inherit from " f"{AuthenticationMixin.__name__}."
        )

    azure_secret = artifact_store.get_authentication_secret(
        expected_schema_type=AzureSecretSchema
    )

    if not azure_secret:
        raise ValueError(
            "Missing secret to authenticate cloud storage for Label Studio."
        )

    return azure_secret


def get_label_studio_annotator(context: StepContext) -> LabelStudioAnnotator:
    annotator = context.stack.annotator  # type: ignore[union-attr]
    if not annotator:
        raise StackComponentInterfaceError(
            "An active annotator is required to run this step."
        )

    if not isinstance(annotator, LabelStudioAnnotator):
        raise TypeError("This step can only be used with the Label Studio annotator.")

    if not annotator._connection_available():
        raise StackComponentInterfaceError("No active annotator.")

    return annotator


def get_artifact_store(context: StepContext) -> AzureArtifactStore:
    artifact_store: AzureArtifactStore = context.stack.artifact_store  # type: ignore[union-attr]

    if not isinstance(artifact_store, AzureArtifactStore):
        raise TypeError(
            "The artifact store must inherit from " f"{AzureArtifactStore.__name__}."
        )
    return artifact_store
