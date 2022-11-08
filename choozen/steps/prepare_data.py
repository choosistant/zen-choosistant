from typing import Any, Dict, List

from zenml.steps import Output, step

from choosistant.data.amazon.download import AmazonReviewDataDownloader


@step
def prepare_amazon_review_dataset() -> Output(file_paths=List[Dict[str, Any]]):
    """Prepare the Amazon Review dataset."""
    categories = [
        "Amazon Fashion",
        "All Beauty",
        "Appliances",
        "Arts, Crafts and Sewing",
        "Automotive",
        # "Cell Phones and Accessories",
        # "Clothing, Shoes and Jewelry",
        # "Electronics",
        # "Home and Kitchen",
        # "Electronics",
    ]
    downloader = AmazonReviewDataDownloader(
        meta_data_path="data/amazon-review-dataset.json",
        categories=categories,
        output_dir="data/raw/amazon-reviews",
        verbose=True,
    )
    downloader.run()
    return [{"stuff": {"more_stuff": ""}}]


# Create a step
prepare_amazon_review_dataset_step = prepare_amazon_review_dataset()
