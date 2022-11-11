from typing import Optional, cast

from label_studio_sdk import Project
from zenml.integrations.label_studio.annotators import LabelStudioAnnotator
from zenml.integrations.label_studio.steps.label_studio_standard_steps import (
    LabelStudioDatasetRegistrationParameters,
)
from zenml.steps import StepContext, step

from choozen.helpers import get_label_studio_annotator


LABEL_STUDIO_UI_CONFIG = """
<View>
  <View style="margin:0;padding:0;">
    <HyperText name="intro">
      <p style="font-family: Helvetica, sans-serif;margin:0;padding:0;">
        Please read the following text and
        highlight phrases where the benefits and drawbacks.</p>
    </HyperText>
  </View>

  <Labels name="pros_and_cons" toName="text" showInline="true">
    <Label value="benefit" background="green"/>
    <Label value="drawback" background="red"/>
  </Labels>

  <View style="border: 1px solid #CCC;border-radius: 5px;padding: 10px">
    <Text name="text" value="$text" granularity="word"/>
  </View>
</View>
"""

params = LabelStudioDatasetRegistrationParameters(
    label_config=LABEL_STUDIO_UI_CONFIG,
    dataset_name="amazon-reviews",
)


@step(enable_cache=False)
def get_or_create_label_studio_project(
    params: LabelStudioDatasetRegistrationParameters,
    context: StepContext,
) -> str:
    annotator: LabelStudioAnnotator = get_label_studio_annotator(context=context)

    lb_project: Optional[Project] = None
    for dataset in annotator.get_datasets():
        if dataset.get_params()["title"] == params.dataset_name:
            lb_project = dataset

    if not lb_project:
        lb_project = annotator.register_dataset_for_annotation(params)

    title = cast(str, lb_project.get_params()["title"])
    return title


get_or_create_label_studio_project_step = get_or_create_label_studio_project(params)
