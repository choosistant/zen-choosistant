from typing import List

from zenml.steps import Output, step

from choosistant.data import Example
from choosistant.data.amazon.download import AmazonReviewDataDownloader
from choosistant.data.amazon.sample import AmazonReviewDataSampler


@step
def prepare_amazon_review_dataset() -> Output(examples=List[Example]):
    """Prepare the Amazon Review dataset."""
    categories = [
        "Amazon Fashion",
        "All Beauty",
        "Appliances",
        "Arts, Crafts and Sewing",
        "Automotive",
        "Cell Phones and Accessories",
        "Clothing, Shoes and Jewelry",
        "Electronics",
        "Home and Kitchen",
        "Electronics",
    ]
    downloader = AmazonReviewDataDownloader(
        meta_data_path="data/amazon-review-dataset.json",
        categories=categories,
        output_dir="data/raw/amazon-reviews",
        verbose=True,
    )
    file_paths = downloader.run()

    examples: List[Example] = []

    for file_path in file_paths:
        sampler = AmazonReviewDataSampler(
            input_path=file_path,
        )
        examples += sampler.sample()

    return examples


# Create a step
prepare_amazon_review_dataset_step = prepare_amazon_review_dataset()
