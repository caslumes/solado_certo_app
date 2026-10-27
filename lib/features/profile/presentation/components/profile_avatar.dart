import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:solado_certo_app/app/theme/app_colors.dart';
import 'package:solado_certo_app/core/network/api_urls.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.url,
    required this.isSaving,
    required this.onChange,
    required this.onRemove,
  });

  static const size = 96.0;

  final String url;
  final bool isSaving;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    const defaultImage = Image(
      image: AssetImage('assets/images/user.png'),
      width: size,
      height: size,
    );

    return Column(
      spacing: 8.0,
      children: [
        SizedBox.square(
          dimension: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipOval(
                child: url.isEmpty
                    ? defaultImage
                    : Semantics(
                        image: true,
                        label: 'Foto de perfil',
                        child: CachedNetworkImage(
                          imageUrl: resolveApiUrl(url),
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              const ColoredBox(color: AppColors.secondaryColor),
                          errorWidget: (_, _, _) => defaultImage,
                        ),
                      ),
              ),
              if (isSaving) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: isSaving ? null : onChange,
              child: Text(
                url.isEmpty ? 'Adicionar foto' : 'Alterar foto',
                style: textStyle,
              ),
            ),
            if (url.isNotEmpty)
              TextButton(
                onPressed: isSaving ? null : onRemove,
                child: Text('Remover foto', style: textStyle),
              ),
          ],
        ),
      ],
    );
  }
}
