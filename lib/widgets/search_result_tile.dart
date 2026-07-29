import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ========================================================================
// COMMENTED OUT: Photon-based SearchResultTile
// ========================================================================
// import 'package:riderzz_app/models/photon_place.dart';
//
// class SearchResultTile extends StatelessWidget {
//   final PhotonPlace place;
//   final VoidCallback onTap;
//
//   const SearchResultTile({
//     super.key,
//     required this.place,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final List<String> addressParts = [];
//     if (place.city != null && place.city!.isNotEmpty) {
//       addressParts.add(place.city!);
//     }
//     if (place.state != null && place.state!.isNotEmpty) {
//       addressParts.add(place.state!);
//     }
//     if (place.country != null && place.country!.isNotEmpty) {
//       addressParts.add(place.country!);
//     }
//     final String completeAddress = addressParts.isEmpty ? 'Unknown location details' : addressParts.join(', ');
//
//     return InkWell(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Padding(
//               padding: EdgeInsets.only(top: 2),
//               child: Text('📍', style: TextStyle(fontSize: 16)),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     place.name,
//                     style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF121214)),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 3),
//                   Text(
//                     completeAddress,
//                     style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF6C6F79), fontWeight: FontWeight.w500),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B8C4), size: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:riderzz_app/models/google_place.dart';

class SearchResultTile extends StatelessWidget {
  final GooglePlace place;
  final VoidCallback onTap;

  const SearchResultTile({
    super.key,
    required this.place,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // For Google Places, displayName is the full text from autocomplete
    // name is the short name (first part before comma)
    final String subtitle = place.displayName.contains(',')
        ? place.displayName.substring(place.displayName.indexOf(',') + 1).trim()
        : '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                '📍',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF121214),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        color: const Color(0xFF6C6F79),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFB0B8C4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
