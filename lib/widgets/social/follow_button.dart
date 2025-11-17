// ==================================================
// Follow Button Widget for WanMap v2
// ==================================================
// Author: AI Assistant
// Created: 2025-01-17
// Purpose: Reusable follow/unfollow button component
// ==================================================

import 'package:flutter/material.dart';
import '../../services/social_service.dart';

class FollowButton extends StatefulWidget {
  final String targetUserId;
  final bool initialIsFollowing;
  final VoidCallback? onFollowChanged;

  const FollowButton({
    super.key,
    required this.targetUserId,
    this.initialIsFollowing = false,
    this.onFollowChanged,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  final SocialService _socialService = SocialService();
  late bool _isFollowing;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.initialIsFollowing;
  }

  Future<void> _toggleFollow() async {
    setState(() => _isLoading = true);

    try {
      if (_isFollowing) {
        await _socialService.unfollowUser(widget.targetUserId);
      } else {
        await _socialService.followUser(widget.targetUserId);
      }

      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _isLoading = false;
        });

        widget.onFollowChanged?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? 'フォローしました' : 'フォロー解除しました'),
            duration: const Duration(seconds: 1),
          ),
        );
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
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isFollowing ? Colors.grey[300] : Theme.of(context).primaryColor,
          foregroundColor: _isFollowing ? Colors.black87 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                _isFollowing ? 'フォロー中' : 'フォロー',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
