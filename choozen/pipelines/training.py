from zenml.pipelines import pipeline


@pipeline(enable_cache=False)
def training_pipeline(
    get_or_create_label_studio_project,
    get_labeled_data,
    convert_annotations,
):
    dataset_name = get_or_create_label_studio_project()
    labeled_data = get_labeled_data(dataset_name)
    texts, labels = convert_annotations(labeled_data)
