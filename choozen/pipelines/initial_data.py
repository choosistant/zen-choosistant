from zenml.pipelines import pipeline


@pipeline(enable_cache=False)
def initial_data_pipeline(
    prepare_data,
    get_or_create_label_studio_project,
    sync_to_label_studio,
):
    """Pipeline to download and convert the initial data."""
    examples = prepare_data()
    dataset_name = get_or_create_label_studio_project()
    sync_to_label_studio(dataset_name, examples)
