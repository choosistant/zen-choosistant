import json

from pathlib import Path
from typing import Any, Dict, List

from choosistant.data import AnnotatedSegment, Example


def parse_label_studio_exported_item(
    exported_annotation_item: Dict[str, Any]
) -> Example:
    example = Example(
        id=exported_annotation_item["data"]["index"],
        reference_id=exported_annotation_item["data"]["asin"],
        text=exported_annotation_item["data"]["reviewText"],
    )

    for annotation_object in exported_annotation_item["annotations"]:
        labeled_segments = annotation_object["result"]
        for labeled_segment in labeled_segments:
            vals = labeled_segment["value"]
            example.annotations.append(
                AnnotatedSegment(
                    label=vals["labels"][0],
                    segment_start=vals["start"],
                    segment_end=vals["end"],
                    segment=vals["text"],
                )
            )
    return example


def parse_label_studio_exported_file(file_path: Path) -> List[Example]:
    if not file_path.exists():
        raise FileNotFoundError(f"File not found: {file_path}")
    with open(file_path, "r") as f:
        items = json.load(f)
        return [parse_label_studio_exported_item(item) for item in items]
