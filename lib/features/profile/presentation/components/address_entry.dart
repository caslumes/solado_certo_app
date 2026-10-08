import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/features/profile/domain/entities/address.dart';

class AddressEntry extends StatelessWidget {
  const AddressEntry({super.key, required this.address});

  final AddressEntity address;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        address.label != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(address.label!.toUpperCase()),
              )
            : SizedBox.shrink(),
        AddressContainer(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${address.number}, ${address.street}'.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        address.district.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppColors.tertiaryColor,
                        ),
                      ),
                      Text(
                        '${address.city} - ${address.state}'.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppColors.tertiaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  address.isDefault ? Icons.star : Icons.star_border,
                  color: address.isDefault
                      ? AppColors.primaryColor
                      : AppColors.tertiaryColor,
                  size: 32.0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AddressContainer extends StatelessWidget {
  const AddressContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.secondaryColor,
      ),
      child: child,
    );
  }
}
