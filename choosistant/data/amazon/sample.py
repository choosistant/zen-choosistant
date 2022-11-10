import json
import random
import re
import uuid

from cmath import inf
from pathlib import Path
from typing import List

import click
import numpy as np
import pandas as pd

from tqdm import tqdm

from choosistant.data import Example


DEFAULT_MIN_WORD_COUNT = 5
DEFAULT_BETA = 0.4
DEFAULT_NUM_ITEMS = 5
DEFAULT_NUM_POSITIVE_REVIEWS = 2
DEFAULT_NUM_NEGATIVE_REVIEWS = 2
DEFAULT_RANDOM_SEED = 0


def preprocess_text(input_text: str):
    output_text = input_text
    output_text = re.sub(r"([\.])[\.]+", r"\1", output_text)
    output_text = re.sub(r"([\.,;:?!])([a-zA-Z]+)", r"\1 \2", output_text)
    output_text = re.sub(r"([a-zA-Z]+)[\.,!?:;]([a-zA-Z]+)", r"\1. \2", output_text)
    output_text = re.sub(r"http\S+", r" ", output_text)
    output_text = output_text.replace(r"\n", r" \n")
    # output_text = re.sub(r"\s{2,}", " ", output_text)
    return output_text


class AmazonReviewDataSampler:
    def __init__(
        self,
        input_path: str,
        output_dir: str = "data/sampled/amazon-reviews",
        min_word_count: int = DEFAULT_MIN_WORD_COUNT,
        beta: float = DEFAULT_BETA,
        n_items: int = DEFAULT_NUM_ITEMS,
        n_positive_reviews: int = DEFAULT_NUM_POSITIVE_REVIEWS,
        n_negative_reviews: int = DEFAULT_NUM_NEGATIVE_REVIEWS,
        random_seed: int = DEFAULT_RANDOM_SEED,
    ) -> None:
        self._input_path = Path(input_path)
        self._min_word_count = min_word_count
        if random_seed is None or random_seed == 0:
            random_seed = random.randint(1, 2**32 - 1)
            print(f"Random seed not specified. Using random seed: {random_seed}")
        self._random_seed = random_seed
        self._random_gen = np.random.default_rng(seed=random_seed)
        self._beta = beta
        self._n_items = n_items
        self._n_positive_reviews = n_positive_reviews
        self._n_negative_reviews = n_negative_reviews

        if not self._input_path.exists():
            ValueError(f"Input file {self._input_path} does not exist.")

        self._output_dir = Path(output_dir)

    def run(self) -> None:
        """Sample a subset of the reviews and write them to disk."""
        df_sampled_reviews = self._perform_sampling()
        self._write_to_disk(df_sampled_reviews=df_sampled_reviews)

    def sample(self) -> List[Example]:
        """Sample a subset of the reviews."""
        df_sampled_reviews = self._perform_sampling()

        examples: List[Example] = []
        for _, row in df_sampled_reviews.iterrows():
            example = Example(
                id=str(uuid.uuid4()),
                reference_id=row["asin"],
                text=row["reviewText"],
            )
            examples.append(example)

        return examples

    def _write_to_disk(self, df_sampled_reviews) -> List[Path]:
        """Write the sampled reviews to disk as a set of files."""
        self._output_dir.mkdir(parents=True, exist_ok=True)

        # Create a name prefix based on input file name
        name_prefix = self._input_path.stem
        if name_prefix.endswith(".json"):
            name_prefix = name_prefix[:-5]

        # Save the sampled reviews to disk
        generated_file_paths: List[Path] = []

        records = df_sampled_reviews.to_dict(orient="records")
        for record in records:
            file_path = (
                self._output_dir / f"{name_prefix}-{record['review_index']}.json"
            )

            with open(file_path, "w") as f:
                json.dump(record, f, indent=2)

            # Record generated file path
            generated_file_paths.append(file_path)

        # Save the list of generated file paths to disk
        gen_file_name = f"{name_prefix}-generated-files-rs{self._random_seed}.txt"
        with open(self._output_dir / gen_file_name, "w") as f:
            f.write("\n".join([str(p.absolute()) for p in generated_file_paths]))

        return generated_file_paths

    def _perform_sampling(self) -> pd.DataFrame:
        """Sample a subset of the reviews."""
        tqdm.pandas()

        df_reviews = self._load_and_filter_data()

        df_items = self._calc_item_stats(df_reviews)

        df_items = self._filter_items(df_items)

        n_filtered_items = len(df_items)

        self._calc_item_sampling_weight(df_items)

        if self._n_items > n_filtered_items:
            msg = (
                f"Requested number of items ({self._n_items}) is greater "
                f"than the number of items after filtering ({n_filtered_items}). "
                "We will not perform any sampling, but use all the filtered items."
            )
            print(msg)

            df_sampled_items = df_items
        else:
            df_sampled_items = df_items.sample(
                n=self._n_items,
                weights="sampling_weight",
                random_state=self._random_gen,
            )

        df_sampled_reviews = self._sample_item_reviews(df_reviews, df_sampled_items)

        return df_sampled_reviews

    def _load_and_filter_data(self) -> pd.DataFrame:
        print(f"Loading chunked data from {self._input_path}...")
        dtypes = {
            "overall": "int8",
            "verified": "bool",
            "reviewTime": "str",
            "reviewerID": "str",
            "asin": "str",
            "reviewerName": "str",
            "reviewText": "str",
            "summary": "str",
            "unixReviewTime": "int64",
        }
        chunker = pd.read_json(
            path_or_buf=self._input_path,
            lines=True,
            chunksize=1_000_000,
            dtype=dtypes,
        )

        extracted_data = []

        for df_data in chunker:
            df_data["review_index"] = df_data.index

            df_data["reviewText"] = df_data["reviewText"].astype(str)

            # Remove data where review text is missing
            df_data = df_data[~df_data["reviewText"].isnull()]
            df_data = df_data[df_data["reviewText"].str.len() > 10]

            # Preprocess text
            print("Preprocessing review texts...")
            df_data["reviewText"] = df_data["reviewText"].progress_apply(
                preprocess_text
            )

            print("Counting words in each review text...")
            df_data["review_text_word_count"] = (
                df_data["reviewText"]
                .progress_apply(lambda x: len(x.split()))
                .astype(int)
            )

            # Remove duplicates
            df_data = df_data.drop_duplicates(
                subset=["reviewText", "asin"], keep="last"
            )

            # Remove reviews which have too few (e.g. 5) words in the review text
            df_data = df_data[df_data["review_text_word_count"] >= self._min_word_count]

            extracted_data.append(
                df_data[["review_index", "asin", "overall", "reviewText"]].copy()
            )

        df_reviews = pd.concat(extracted_data)
        return df_reviews

    def _calc_item_stats(self, df_data: pd.DataFrame) -> pd.DataFrame:
        df_item_stats = df_data.groupby("asin").agg(
            n_reviews=("review_index", "count"),
            rating_avg=("overall", "mean"),
            rating_median=("overall", "median"),
            rating_min=("overall", "min"),
            rating_max=("overall", "max"),
        )

        # Bin review ratings into 2 bins;
        # - negative bin for ratings 1, 2, and 3
        # - positive bin for ratings 4 and 5
        df_binned = pd.cut(
            x=df_data.overall,
            bins=[0, 3, 5],
            labels=["negative_review_count", "positive_review_count"],
        )
        df_review_counts = df_data.groupby(["asin", df_binned]).size().unstack()

        # Merge the review counts into the product stats
        df_item_stats = pd.merge(
            left=df_item_stats,
            right=df_review_counts,
            left_index=True,
            right_index=True,
        )
        return df_item_stats

    def _filter_items(self, df_items: pd.DataFrame) -> pd.DataFrame:
        # Remove items which do not have at least 1 negative review and 1 positive review
        has_negative_reviews = (
            df_items.negative_review_count >= self._n_negative_reviews
        )
        has_positive_reviews = (
            df_items.positive_review_count >= self._n_positive_reviews
        )
        df_filtered_items = df_items[has_negative_reviews & has_positive_reviews].copy()

        return df_filtered_items

    def _calc_item_sampling_weight(self, df_items: pd.DataFrame) -> None:
        """Compute sampling weights for each item."""

        if self._beta == 0 or self._beta == inf:
            # We will use uniform sampling. No need to compute the sampling weight.
            df_items["sampling_weight"] = 1
            return

        # Assign a score to each item based on how balanced the reviews are.
        # The score is the ratio of the number of positive reviews to the number of negative reviews:
        # - A score of 1 means the number of positive reviews is equal to the number of negative reviews.
        # - A score of 0 means there are no positive/negative reviews.
        review_count_cols = ["positive_review_count", "negative_review_count"]
        min_counts = df_items[review_count_cols].min(axis=1)
        max_counts = df_items[review_count_cols].max(axis=1)
        df_items["review_balance_score"] = min_counts / max_counts

        # Assign a score to each item based on how many reviews it has.
        review_counts = (
            df_items["positive_review_count"] + df_items["negative_review_count"]
        )

        # Perform min-max scaling
        review_counts_scaled = (review_counts - review_counts.min()) / (
            review_counts.max() - review_counts.min()
        )
        df_items["review_count_score"] = review_counts_scaled

        # Combine the two scores to get a final weight for each item.
        df_items["sampling_weight"] = (
            self._beta * df_items["review_balance_score"]
            + (1 - self._beta) * df_items["review_count_score"]
        )

    def _sample_item_reviews(
        self, df_reviews: pd.DataFrame, df_items: pd.DataFrame
    ) -> None:
        """Sample reviews for the given items."""

        # Filter reviews to only include reviews for the sampled items.
        df_filtered_reviews = df_reviews[df_reviews.asin.isin(df_items.index)]

        # Split the reviews into positive and negative reviews.
        df_negative_reviews = df_filtered_reviews[(df_filtered_reviews.overall <= 3)]
        df_positive_reviews = df_filtered_reviews[(df_filtered_reviews.overall > 3)]

        # Sample the negative reviews.
        df_sampled_neg_reviews = df_negative_reviews.groupby("asin").sample(
            n=self._n_negative_reviews, replace=False, random_state=self._random_gen
        )

        # Sample the positive reviews.
        df_sampled_pos_reviews = df_positive_reviews.groupby("asin").sample(
            n=self._n_positive_reviews, replace=False, random_state=self._random_gen
        )

        return pd.concat([df_sampled_neg_reviews, df_sampled_pos_reviews])

    def _convert_to_examples(self, df_reviews: pd.DataFrame) -> List[Example]:
        """Convert the reviews into a list of examples."""

        examples: List[Example] = []
        for _, row in df_reviews.iterrows():
            examples.append(
                Example(
                    id=uuid.uuid4(),
                    reference_id=row["asin"],
                    text=row["reviewText"],
                )
            )
        return examples


@click.command(help="Prepares the Amazon review data set.")
@click.option(
    "-i",
    "--input-path",
    type=click.STRING,
    required=True,
)
@click.option(
    "-o",
    "--output-dir",
    type=click.STRING,
    required=True,
)
@click.option(
    "--min-word-count",
    help="The minimum number of words required for each review text.",
    type=click.INT,
    required=False,
    default=DEFAULT_MIN_WORD_COUNT,
    show_default=True,
)
@click.option(
    "--beta",
    help="Used to compute the non-uniform sampling weights for each item. Set it to 0 to disable non-uniform sampling.",
    type=click.FLOAT,
    required=False,
    default=DEFAULT_BETA,
    show_default=True,
)
@click.option(
    "--n-items",
    help="Number of items to sample.",
    type=click.INT,
    required=False,
    default=DEFAULT_NUM_ITEMS,
    show_default=True,
)
@click.option(
    "--n-positive-reviews",
    help="Number of positive reviews to sample from each item.",
    type=click.INT,
    required=False,
    default=DEFAULT_NUM_POSITIVE_REVIEWS,
    show_default=True,
)
@click.option(
    "--n-negative-reviews",
    help="Number of negative reviews to sample from each item.",
    type=click.INT,
    required=False,
    default=DEFAULT_NUM_NEGATIVE_REVIEWS,
    show_default=True,
)
@click.option(
    "--random-seed",
    help="Random seed to use for sampling. Use 0 to manual random seed.",
    type=click.INT,
    required=False,
    default=DEFAULT_RANDOM_SEED,
    show_default=True,
)
def main(**kwargs):
    AmazonReviewDataSampler(**kwargs).run()


if __name__ == "__main__":
    main()  # pylint: disable=no-value-for-parameter
