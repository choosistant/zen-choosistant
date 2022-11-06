from dataclasses import dataclass, field
from typing import Dict, List


LABEL_TO_ID_MAPPING: Dict[str, int] = {"benefit": 0, "drawback": 1}


@dataclass
class AnnotatedSegment:
    label: str
    segment_start: int
    segment_end: int
    segment: str


@dataclass
class Example:
    id: int
    reference_id: str
    text: str
    annotations: List[AnnotatedSegment] = field(default_factory=list)
