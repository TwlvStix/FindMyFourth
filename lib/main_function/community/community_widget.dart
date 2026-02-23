import '/core/widgets/fairway_background.dart';
import '/core/design_tokens/typography.dart';
import '/core/design_tokens/colors.dart';
import '/chat_group/chat/chat_widget.dart';
import 'package:flutter/material.dart';

class CommunityWidget extends StatefulWidget {
  const CommunityWidget({super.key});

  static String routeName = 'Community';
  static String routePath = '/community';

  @override
  State<CommunityWidget> createState() => _CommunityWidgetState();
}

class _CommunityWidgetState extends State<CommunityWidget> {

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Text(
            'Chats',
            style: AppTypography.headlineMediumSans.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: FairwayBackgroundDark(
          showOrganic: true,
          showTexture: true,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 56),
                // Content area
                Expanded(
                  child: KeepAliveWidgetWrapper(
                    builder: (context) => ChatWidget(isEmbedded: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Keep alive widget wrapper to preserve tab state
class KeepAliveWidgetWrapper extends StatefulWidget {
  final Widget Function(BuildContext) builder;

  const KeepAliveWidgetWrapper({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  State<KeepAliveWidgetWrapper> createState() =>
      _KeepAliveWidgetWrapperState();
}

class _KeepAliveWidgetWrapperState extends State<KeepAliveWidgetWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.builder(context);
  }
}
