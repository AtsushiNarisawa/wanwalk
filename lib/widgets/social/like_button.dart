// ==================================================
// Like Button Widget for WanMap v2
// ==================================================
// Author: AI Assistant
// Created: 2025-01-17
// Purpose: Reusable like/unlike button component for routes
// ==================================================

import 'package:flutter/material.dart';
import '../../services/social_service.dart';

class LikeButton extends StatefulWidget {
  final String routeId;
  final bool initialIsLiked;
  final int initialLikesCount;
  final VoidCallback? onLikeChanged;

  const LikeButton({
    super.key,
    required this.routeId,
    this.initialIsLiked = false,
    this.initialLikesCount = 0,
    this.onLikeChanged,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  final SocialService _socialService = SocialService();
  late bool _isLiked;
  late int _likesCount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialIsLiked;
    _likesCount = widget.initialLikesCount;
  }

  Future<void> _toggleLike() async {
    setState(() => _isLoading = true);

    try {
      if (_isLiked) {
        await _socialService.unlikeRoute(widget.routeId);
        if (mounted) {
          setState(() {
            _isLiked = false;
            _likesCount = (_likesCount - 1).clamp(0, 999999);
          });
        }
      } else {
        await _socialService.likeRoute(widget.routeId);
        if (mounted) {
          setState(() {
            _isLiked = true;
            _likesCount++;
          });
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        widget.onLikeChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _isLoading ? null : _toggleLike,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.grey[600],
                ),
        ),
        Text(
          _likesCount > 0 ? '$_likesCount' : '',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
