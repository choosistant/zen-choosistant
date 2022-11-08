import json

from dataclasses import dataclass
from io import BufferedWriter
from pathlib import Path
from typing import List, Union

import click
import requests

from tqdm import tqdm


@dataclass
class CategoryItem:
    name: str
    reviews_url: str
    reviews_count: int
    ratings_url: str
    ratings_count: int

    @property
    def slug(self) -> str:
        return self.name.replace(" ", "-").lower()


class FileDownloader:
    def __init__(self, url: str, output_file_path: Path, verbose: bool = True):
        self._url = url
        self._output_file_path = output_file_path
        self._verbose = verbose

    def run(self) -> None:
        with requests.head(self._url) as response:
            response.raise_for_status()
            file_size_online = int(response.headers.get("Content-length", 100000000))

        if self._output_file_path.exists():
            file_size_offline = self._output_file_path.stat().st_size
            if file_size_offline != file_size_online:
                if self._verbose:
                    print(
                        f"File {self._output_file_path} has not finished downloading."
                    )
                self._resume_file_download(byte_position=file_size_offline)
            else:
                if self._verbose:
                    print(f"File {self._output_file_path} has already been downloaded.")
        else:
            if self._verbose:
                print(f"File {self._output_file_path} does not exist.")
            self._begin_new_file_download()

    def _resume_file_download(self, byte_position: int):
        if self._verbose:
            print(f"Resuming file download from {self._url}...")

        request_headers = {"Range": f"bytes={byte_position}-"}
        with requests.get(self._url, stream=True, headers=request_headers) as r:
            with open(self._output_file_path, "ab") as f:
                self._perform_download(
                    response=r,
                    file_handle=f,
                    initial_byte_position=byte_position,
                )

    def _begin_new_file_download(self):
        if self._verbose:
            print(f"Downloading file from {self._url}...")
        with requests.get(self._url, stream=True) as r:
            with open(self._output_file_path, "wb") as f:
                self._perform_download(
                    response=r,
                    file_handle=f,
                    initial_byte_position=0,
                )

    def _perform_download(
        self,
        response: requests.Response,
        file_handle: BufferedWriter,
        initial_byte_position: int,
    ):
        response.raise_for_status()
        file_size = int(response.headers.get("Content-length", 100000000))
        pbar = None
        if self._verbose:
            pbar = tqdm(
                total=file_size,
                initial=initial_byte_position,
                unit="bytes",
                unit_scale=True,
            )
        for chunk in response.iter_content(chunk_size=8192):
            file_handle.write(chunk)
            if pbar:
                pbar.update(len(chunk))
        if pbar:
            pbar.close()


class AmazonReviewDataDownloader:
    def __init__(
        self,
        meta_data_path: str,
        categories: Union[str, List[str]],
        output_dir: str,
        verbose: bool,
    ):
        self._meta_data_path = Path(meta_data_path)
        if not self._meta_data_path.exists():
            raise ValueError(f"Meta data file {self._meta_data_path} does not exist")

        with open(self._meta_data_path, "r") as f:
            self._meta_data = json.load(f)

        self._available_categories = [
            CategoryItem(**item) for item in self._meta_data["categories"]
        ]

        self._selected_categories = self._parse_categories(
            input_categories=categories,
            available_categories=self._available_categories,
        )

        self._output_dir = Path(output_dir)
        if self._output_dir.exists() and not self._output_dir.is_dir():
            raise ValueError(f"Output directory {self._output_dir} is not a directory")
        else:
            self._output_dir.mkdir(parents=True, exist_ok=True)

        self._verbose = verbose

    def run(self) -> List[Path]:
        output_file_paths: List[Path] = []
        for category in self._selected_categories:
            file_name = f"reviews-{category.slug}-{category.reviews_count}.json.gz"
            output_file_path = self._output_dir / file_name
            self._download_file(
                url=category.reviews_url, output_file_path=output_file_path
            )
            output_file_paths.append(output_file_path)
        return output_file_paths

    def _download_file(self, url: str, output_file_path: Path):
        FileDownloader(
            url=url,
            output_file_path=output_file_path,
            verbose=self._verbose,
        ).run()

    def _parse_categories(
        self,
        input_categories: Union[str, List[str]],
        available_categories: List[CategoryItem],
    ) -> List[CategoryItem]:
        if input_categories is None:
            return [item for item in available_categories]

        if isinstance(input_categories, str):
            if input_categories == "" or input_categories.lower() == "all":
                return [item for item in available_categories]
            else:
                input_categories = input_categories.split(";")

        selected_categories: List[CategoryItem] = []

        avail_catagory_names = [item.name.lower() for item in available_categories]
        for c in input_categories:
            try:
                category_idx = avail_catagory_names.index(c.lower().strip())
            except ValueError:
                raise ValueError(
                    f"Name '{c}' is not a valid category. Cannot be found in meta data."
                )
            selected_categories.append(available_categories[category_idx])
        return selected_categories


@click.command(help="Downloads the Amazon review data set.")
@click.option(
    "--meta-data-path",
    type=click.STRING,
    required=True,
)
@click.option(
    "--categories",
    type=click.STRING,
    required=False,
    default="all",
    show_default=True,
)
@click.option(
    "-o",
    "--output-dir",
    type=click.STRING,
    required=True,
)
@click.option(
    "--verbose",
    is_flag=True,
    show_default=True,
    default=False,
)
def main(**kwargs):
    AmazonReviewDataDownloader(**kwargs).run()


if __name__ == "__main__":
    main()  # pylint: disable=no-value-for-parameter
