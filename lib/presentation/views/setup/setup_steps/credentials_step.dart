import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_stock/presentation/views/auth/login_screen.dart';
import '../../../controllers/setup_controller.dart';
import 'setup_step_kit.dart';

class CredentialsStep extends GetView<SetupController> {
  const CredentialsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final isPasswordVisible = false.obs;
    final isConfirmVisible = false.obs;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepHeader(
            icon: Icons.lock_rounded,
            title: 'secureYourAccountTitle'.tr,
            subtitle: 'secureYourAccountSubtitle'.tr,
          ),
          const SizedBox(height: 24),

          SetupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SetupFieldLabel('usernameLabel'.tr, required: true),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'chooseUsernameHint'.tr,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  onChanged: controller.updateUsername,
                ),
                const SizedBox(height: 18),

                SetupFieldLabel('passwordLabel'.tr, required: true),
                Obx(
                      () => TextField(
                    obscureText: !isPasswordVisible.value,
                    decoration: InputDecoration(
                      hintText: 'minCharactersHint'.tr,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible.value ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        ),
                        onPressed: () => isPasswordVisible.toggle(),
                      ),
                    ),
                    onChanged: controller.updatePassword,
                  ),
                ),
                const SizedBox(height: 18),

                SetupFieldLabel('confirmPasswordLabel'.tr, required: true),
                Obx(
                      () => TextField(
                    obscureText: !isConfirmVisible.value,
                    decoration: InputDecoration(
                      hintText: 'reEnterPasswordHint'.tr,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmVisible.value ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        ),
                        onPressed: () => isConfirmVisible.toggle(),
                      ),
                      errorText: controller.confirmPassword.value.isNotEmpty &&
                          controller.password.value != controller.confirmPassword.value
                          ? 'passwordsDoNotMatchError'.tr
                          : null,
                    ),
                    onChanged: controller.updateConfirmPassword,
                  ),
                ),
                SizedBox(height: 16,),
                TextButton(onPressed: (){
                  //Get.offAll(LoginScreen());
                }, 
                    child: Text('AlreadyHaveAccount'.tr))
              ],
            ),
          ),
          const SizedBox(height: 16),

          SetupCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                      () => _RequirementRow(
                    met: controller.password.value.length >= 6,
                    text: 'atLeastMinCharactersReq'.tr,
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                      () => _RequirementRow(
                    met: controller.password.value.isNotEmpty &&
                        controller.password.value == controller.confirmPassword.value,
                    text: 'passwordsMatchReq'.tr,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Obx(
                () => ValidationBanner(
              isValid: controller.step5Valid.value,
              validText: 'credentialsValidText'.tr,
              invalidText: 'fillFieldsToFinishSetupText'.tr,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final bool met;
  final String text;

  const _RequirementRow({required this.met, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = met ? const Color(0xFF16A34A) : scheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(met ? Icons.check_circle_rounded : Icons.circle_outlined, color: color, size: 18),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: color, fontSize: 13.5, fontWeight: met ? FontWeight.w600 : FontWeight.w400)),
      ],
    );
  }
}