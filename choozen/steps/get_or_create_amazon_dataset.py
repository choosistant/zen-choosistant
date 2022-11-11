from zenml.integrations.label_studio.steps.label_studio_standard_steps import (
    LabelStudioDatasetRegistrationParameters,
    get_or_create_dataset,
)


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

label_studio_registration_params = LabelStudioDatasetRegistrationParameters(
    label_config=LABEL_STUDIO_UI_CONFIG,
    dataset_name="amazon-reviews",
)

get_or_create_amazon_dataset_step = get_or_create_dataset(
    label_studio_registration_params
)
