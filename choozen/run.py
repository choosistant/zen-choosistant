import click

from choozen.pipelines.initial_data import initial_data_pipeline
from choozen.pipelines.training import training_pipeline
from choozen.steps import (
    convert_annotations_step,
    get_labeled_data_step,
    get_or_create_amazon_dataset_step,
    prepare_amazon_review_dataset_step,
)


@click.command()
@click.argument("pipeline")
def main(pipeline: str) -> None:
    if pipeline in ["train", "training"]:
        pipeline_fn = training_pipeline(
            get_or_create_dataset=get_or_create_amazon_dataset_step,
            get_labeled_data=get_labeled_data_step,
            convert_annotations=convert_annotations_step,
        )
    elif pipeline in ["inital_data", "initial-data"]:
        pipeline_fn = initial_data_pipeline(
            prepare_data=prepare_amazon_review_dataset_step,
            # upload_to_label_studio=upload_to_label_studio_step,
        )
    else:
        raise ValueError(f"Pipeline {pipeline} not found.")

    pipeline_fn.run(unlisted=True)


if __name__ == "__main__":
    main()
