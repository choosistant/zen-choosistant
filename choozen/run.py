import click

from choozen.pipelines.training import training_pipeline
from choozen.steps.convert_annotations import convert_annotations_step
from choozen.steps.get_labeled_data import get_labeled_data_step
from choozen.steps.get_or_create_amazon_dataset import (
    get_or_create_amazon_dataset_step,
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
        pipeline_fn.run()
    else:
        raise ValueError(f"Pipeline {pipeline} not found.")


if __name__ == "__main__":
    main()
