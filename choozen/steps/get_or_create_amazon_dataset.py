from zenml.integrations.label_studio.steps.label_studio_standard_steps import (
    LabelStudioDatasetRegistrationParameters,
    get_or_create_dataset,
)


LABEL_STUDIO_UI_CONFIG = """
<View>
  <Labels name="pros_and_cons" toName="text" showInline="true">
    <Label value="benefit" background="green"/>
    <Label value="drawback" background="red"/>
  </Labels>
  <Header value="Please label the text below."/>
  <Text name="text" value="$text" granularity="word"/>
</View>
"""

label_studio_registration_params = LabelStudioDatasetRegistrationParameters(
    label_config=LABEL_STUDIO_UI_CONFIG,
    dataset_name="amazon-reviews",
)

get_or_create_amazon_dataset_step = get_or_create_dataset(
    label_studio_registration_params
)
