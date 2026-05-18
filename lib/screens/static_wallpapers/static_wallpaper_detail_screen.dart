// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../../models/wallpaper_model.dart';
// import '../../providers/favorites_provider.dart';
//
// class StaticWallpaperDetailScreen extends StatelessWidget {
//   const StaticWallpaperDetailScreen({
//     super.key,
//     required this.wallpaper,
//   });
//
//   final WallpaperModel wallpaper;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         foregroundColor: const Color(0xFFFF7597),
//         title: const Text('Static Wallpaper'),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: InteractiveViewer(
//               child: CachedNetworkImage(
//                 imageUrl: wallpaper.imageUrl,
//                 width: double.infinity,
//                 fit: BoxFit.contain,
//                 placeholder: (_, __) => const Center(
//                   child: CircularProgressIndicator(
//                     color: Color(0xFFFF7597),
//                   ),
//                 ),
//                 errorWidget: (_, __, ___) => const Center(
//                   child: Icon(
//                     Icons.broken_image_outlined,
//                     color: Color(0xFFFF7597),
//                     size: 38,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           SafeArea(
//             top: false,
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//               child: Consumer<FavoritesProvider>(
//                 builder: (context, favorites, _) {
//                   final isFavorite = favorites.isFavorite(wallpaper);
//                   return FilledButton.icon(
//                     style: FilledButton.styleFrom(
//                       backgroundColor: const Color(0xFFFF7597),
//                       foregroundColor: Colors.white,
//                       minimumSize: const Size(double.infinity, 52),
//                     ),
//                     onPressed: () => favorites.toggleFavorite(wallpaper),
//                     icon: Icon(
//                       isFavorite
//                           ? Icons.favorite_rounded
//                           : Icons.favorite_border_rounded,
//                     ),
//                     label: Text(
//                       isFavorite ? 'Remove from favorites' : 'Add to favorites',
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
