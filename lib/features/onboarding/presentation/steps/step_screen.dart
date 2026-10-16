import 'package:flutter/widgets.dart';
import 'package:traininpink_onboarding/features/onboarding/domain/flow_config.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/choice_step_view.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/info_step_view.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/tape_step_view.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/text_step_view.dart';
import 'package:traininpink_onboarding/features/onboarding/presentation/steps/week_step_view.dart';

/// One screen per step *type*, never per question. The switch is exhaustive
/// over the sealed step types, so adding a new type to the config parser
/// fails to compile here until it has a screen.
class StepScreen extends StatelessWidget {
  const StepScreen({required this.step, super.key});

  final FlowStep step;

  @override
  Widget build(BuildContext context) => switch (step) {
    final ChoiceStep step => ChoiceStepView(step: step),
    final TextInputStep step => TextStepView(step: step),
    final NumberStep step => TapeStepView(step: step),
    final InfoStep step => InfoStepView(step: step),
    final FrequencyStep step => WeekStepView(steps: [step]),
  };
}
