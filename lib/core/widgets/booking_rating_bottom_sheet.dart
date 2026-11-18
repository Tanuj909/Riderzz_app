import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:riderzz_app/core/models/rating_model.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/user/home/providers/booking_provider.dart';
import 'package:riderzz_app/features/driver/home/data/repositories/driver_repository.dart';

class BookingRatingBottomSheet {
  /// Open rating bottom sheet for Customer
  static Future<void> showCustomer({
    required BuildContext context,
    required BookingModel booking,
    VoidCallback? onRatingSubmitted,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CustomerRatingSheetContent(
        booking: booking,
        onRatingSubmitted: onRatingSubmitted,
      ),
    );
  }

  /// Open rating bottom sheet for Driver
  static Future<void> showDriver({
    required BuildContext context,
    required BookingModel booking,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _DriverRatingSheetContent(
        booking: booking,
      ),
    );
  }
}

// ==========================================
// CUSTOMER RATING BOTTOM SHEET
// ==========================================
class _CustomerRatingSheetContent extends StatefulWidget {
  final BookingModel booking;
  final VoidCallback? onRatingSubmitted;

  const _CustomerRatingSheetContent({
    required this.booking,
    this.onRatingSubmitted,
  });

  @override
  State<_CustomerRatingSheetContent> createState() =>
      _CustomerRatingSheetContentState();
}

class _CustomerRatingSheetContentState
    extends State<_CustomerRatingSheetContent> {
  bool _isLoading = true;
  String? _error;
  BookingRatingData? _ratingData;

  // Form State
  int _selectedStars = 4;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _quickCompliments = [
    'Fast and safe delivery!',
    'Polite and professional',
    'On-time delivery',
    'Handled goods carefully',
    'Great experience',
  ];

  @override
  void initState() {
    super.initState();
    _fetchRating();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _fetchRating() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookingProvider = context.read<BookingProvider>();
      final data = await bookingProvider.fetchBookingRating(widget.booking.id);
      if (mounted) {
        setState(() {
          _ratingData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load rating';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final bookingProvider = context.read<BookingProvider>();
    String reviewText = _reviewController.text.trim().isNotEmpty
        ? _reviewController.text.trim()
        : 'Fast and safe delivery!';
    if (reviewText.length > 500) {
      reviewText = reviewText.substring(0, 500);
    }

    final success = await bookingProvider.submitRating(
      bookingId: widget.booking.id,
      ratingType: 'CUSTOMER_TO_DRIVER',
      stars: _selectedStars,
      review: reviewText,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rating submitted successfully!',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      widget.onRatingSubmitted?.call();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bookingProvider.errorMessage ?? 'Failed to submit rating',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _getStarLabel(int stars) {
    switch (stars) {
      case 1:
        return 'Terrible 😞';
      case 2:
        return 'Poor 🙁';
      case 3:
        return 'Average 😐';
      case 4:
        return 'Very Good 😊';
      case 5:
      default:
        return 'Excellent! 🌟';
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final min = dt.minute.toString().padLeft(2, '0');
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year • $hour:$min $amPm';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottomInset > 0 ? bottomInset + 20 : 28,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Grab Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF9C3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFEAB308),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _ratingData?.customerToDriverRating != null
                              ? 'Rating'
                              : 'Give Driver Your Rating',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 18),

              // Content based on state
              if (_isLoading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFC62E42),
                    ),
                  ),
                ),
              ] else if (_error != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _fetchRating,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ] else if (_ratingData?.customerToDriverRating != null) ...[
                // VIEW RATING MODE (Already rated)
                _buildViewRatingContent(_ratingData!.customerToDriverRating!),
              ] else ...[
                // SUBMIT RATING MODE (Rating is null)
                _buildSubmitRatingContent(),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

  // --- SUBMIT RATING CONTENT ---
  Widget _buildSubmitRatingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.booking.driver != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: const Icon(Icons.person, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.booking.driver!.fullName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Delivery Partner',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Star Rating Selector
        Center(
          child: Column(
            children: [
              Text(
                'How was your experience?',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  final isSelected = star <= _selectedStars;
                  return GestureDetector(
                    onTap: _isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _selectedStars = star;
                            });
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(
                        isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isSelected
                            ? const Color(0xFFEAB308)
                            : const Color(0xFFCBD5E1),
                        size: 42,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _getStarLabel(_selectedStars),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFCA8A04),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quick Feedback Chips
        Text(
          'Quick Feedback',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickCompliments.map((compliment) {
            final isAdded = _reviewController.text.contains(compliment);
            return GestureDetector(
              onTap: _isSubmitting
                  ? null
                  : () {
                      setState(() {
                        if (isAdded) {
                          _reviewController.text = _reviewController.text
                              .replaceAll(compliment, '')
                              .trim();
                        } else {
                          String newText = _reviewController.text.trim().isEmpty
                              ? compliment
                              : '${_reviewController.text.trim()}, $compliment';
                          if (newText.length > 500) {
                            newText = newText.substring(0, 500);
                          }
                          _reviewController.text = newText;
                        }
                      });
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isAdded
                      ? const Color(0xFFFEF2F4)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAdded
                        ? const Color(0xFFC62E42)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  compliment,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isAdded ? FontWeight.w700 : FontWeight.w500,
                    color: isAdded
                        ? const Color(0xFFC62E42)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // Review Text Field
        Text(
          'Your Comments',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reviewController,
          enabled: !_isSubmitting,
          maxLength: 500,
          maxLines: 3,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: 'Tell us more about your experience (optional)...',
            hintStyle: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
            counterStyle: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFC62E42), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Submit Button (Full Width)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitRating,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62E42),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Submit Rating',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // --- VIEW RATING CONTENT ---
  Widget _buildViewRatingContent(RatingItemModel rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Star Score Card (Compact with Star icons and out of 5 Stars on right)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFEF08A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final isSelected = index < rating.stars;
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isSelected
                          ? const Color(0xFFEAB308)
                          : const Color(0xFFCBD5E1),
                      size: 20,
                    ),
                  );
                }),
              ),
              Text(
                '${rating.stars} out of 5 Stars',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF854D0E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Review Text
        if (rating.review != null && rating.review!.trim().isNotEmpty) ...[
          Text(
            'Your Review',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 220,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        rating.review!,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Date
        if (rating.createdAt != null) ...[
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Text(
                'Submitted on ${_formatDate(rating.createdAt)}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Close Button (Full width, rounded)
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: const StadiumBorder(),
            ),
            child: Text(
              'Done',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// DRIVER RATING BOTTOM SHEET
// ==========================================
class _DriverRatingSheetContent extends StatefulWidget {
  final BookingModel booking;

  const _DriverRatingSheetContent({required this.booking});

  @override
  State<_DriverRatingSheetContent> createState() =>
      _DriverRatingSheetContentState();
}

class _DriverRatingSheetContentState extends State<_DriverRatingSheetContent> {
  bool _isLoading = true;
  String? _error;
  BookingRatingData? _ratingData;

  @override
  void initState() {
    super.initState();
    _fetchRating();
  }

  Future<void> _fetchRating() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<DriverRepository>();
      final data = await repo.getBookingRating(widget.booking.id);
      if (mounted) {
        setState(() {
          _ratingData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load rating';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final min = dt.minute.toString().padLeft(2, '0');
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$day $month $year • $hour:$min $amPm';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 28),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Grab Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF9C3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFEAB308),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Rating',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 18),

                if (_isLoading) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFC62E42),
                      ),
                    ),
                  ),
                ] else if (_error != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(
                          _error!,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _fetchRating,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ] else if (_ratingData?.customerToDriverRating != null) ...[
                  _buildDriverRatingDetails(_ratingData!.customerToDriverRating!),
                ] else ...[
                  // NULL RATING (Customer hasn't rated yet)
                  _buildNoRatingYet(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverRatingDetails(RatingItemModel rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Rating Score Card (Compact with Star icons and out of 5 Stars on right)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFEF08A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final isSelected = index < rating.stars;
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isSelected
                          ? const Color(0xFFEAB308)
                          : const Color(0xFFCBD5E1),
                      size: 20,
                    ),
                  );
                }),
              ),
              Text(
                '${rating.stars} out of 5 Stars',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF854D0E),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        if (rating.review != null && rating.review!.trim().isNotEmpty) ...[
          Text(
            'Customer Review',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 220,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        rating.review!,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (rating.createdAt != null) ...[
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Text(
                'Given on ${_formatDate(rating.createdAt)}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: const StadiumBorder(),
            ),
            child: Text(
              'Close',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoRatingYet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              size: 44,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'No Rating Yet',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The customer has not provided a rating or review for this ride yet.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Close',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

