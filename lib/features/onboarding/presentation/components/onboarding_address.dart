import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solado_certo_app/app/bootstrap.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_button.dart';
import 'package:solado_certo_app/core/presentation/components/shoe_text_button.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:solado_certo_app/features/profile/domain/usecases/add_address_use_case.dart';
import 'package:solado_certo_app/features/profile/presentation/components/address_entry.dart';
import 'package:solado_certo_app/features/profile/presentation/pages/address_form_page.dart';

class OnboardingAddress extends StatelessWidget {
  const OnboardingAddress({super.key});

  Future<void> _addAddress(
    BuildContext context,
    OnboardingInProgress state,
  ) async {
    final onboardingBloc = context.read<OnboardingBloc>();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddressFormPage(
          initialReceiver: state.onboardingDraft.profile.name,
          initialIsDefault: state.onboardingDraft.addresses.isEmpty,
          onSubmit: getIt<AddAddressUseCase>().execute,
        ),
      ),
    );
    if (saved == true) onboardingBloc.add(ReloadAddressesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final onboardingBloc = BlocProvider.of<OnboardingBloc>(context);
    final buttonTextStyle = Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(color: Colors.white);

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final addresses = (state is OnboardingInProgress)
            ? state.onboardingDraft.addresses
            : [];
        return Scaffold(
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 15.0),
                child: Image(
                  image: AssetImage('assets/images/logo.png'),
                  width: MediaQuery.of(context).size.width * 0.2,
                ),
              ),
              Container(color: AppColors.primaryColor, height: 5),
              SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: Column(
                        children: [
                          Text(
                            'Endereços'.toUpperCase(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              0.0,
                              16.0,
                              0.0,
                              16.0,
                            ),
                            child: Column(
                              spacing: 16.0,
                              children: [
                                ...(addresses.map(
                                  (e) => AddressEntry(address: e),
                                )),
                                ShoeButton(
                                  onPressed: state is OnboardingInProgress
                                      ? () => _addAddress(context, state)
                                      : null,
                                  filled: false,
                                  child: AddressContainer(
                                    child: Center(
                                      child: Icon(
                                        Icons.add,
                                        color: AppColors.primaryColor,
                                        size: 48.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  spacing: 16.0,
                  children: [
                    ShoeTextButton(
                      onPressed: () {
                        onboardingBloc.add(RetreatOnboardingEvent());
                      },
                      text: "Voltar".toUpperCase(),
                      textStyle: buttonTextStyle,
                    ),
                    ShoeTextButton(
                      onPressed: () {
                        onboardingBloc.add(AdvanceOnboardingEvent());
                      },
                      text: "Avançar".toUpperCase(),
                      textStyle: buttonTextStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }
}
