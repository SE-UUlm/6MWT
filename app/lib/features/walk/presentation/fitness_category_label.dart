import '../../../l10n/app_localizations.dart';
import '../domain/fitness_assessment.dart';

String fitnessCategoryLabel(AppLocalizations l10n, FitnessCategory category) =>
    switch (category) {
      FitnessCategory.reducedPhysicalPerformance =>
        l10n.fitnessReducedPhysicalPerformance,
      FitnessCategory.lowNormal => l10n.fitnessLowNormal,
      FitnessCategory.normalPopulationMean => l10n.fitnessNormalPopulationMean,
      FitnessCategory.highNormal => l10n.fitnessHighNormal,
      FitnessCategory.topPerformance => l10n.fitnessTopPerformance,
    };
