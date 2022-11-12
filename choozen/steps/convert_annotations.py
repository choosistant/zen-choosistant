from typing import Any, Dict, List

from zenml.steps import Output, step

from choosistant.data.amazon import parse_label_studio_exported_item


@step
def convert_annotations(
    label_studio_annotations: List[Dict[Any, Any]]
) -> Output(texts=List, labels=List):
    """Converts the annotation from Label Studio to a two lists."""
    texts, labels = [], []
    for item in label_studio_annotations:
        example = parse_label_studio_exported_item(item)
        for annotation in example.annotations:
            texts.append(annotation.segment)
            labels.append(annotation.label)
    return texts, labels


# Create a step
convert_annotations_step = convert_annotations()
