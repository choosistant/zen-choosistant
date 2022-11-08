from zenml.pipelines import pipeline


@pipeline(enable_cache=False)
def initial_data_pipeline(
    prepare_data,
    # get_or_create_dataset,
    # sample_data,
    # upload_to_label_studio,
):
    """Pipeline to download and convert the initial data."""
    prepare_data()
    # dataset_name = get_or_create_dataset()
    # upload_to_label_studio(prepared_data, dataset_name)
