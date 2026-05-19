import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    ('Chào mừng Sfinity', 'Khám phá nội dung và quản lý yêu thích của bạn.'),
    ('Tìm kiếm thông minh', 'Lọc, sắp xếp và tìm nội dung nhanh chóng.'),
    ('Kết nối mọi lúc', 'Đăng nhập để đồng bộ dữ liệu trên mọi thiết bị.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final (title, subtitle) = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch, size: 80, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 24),
                        Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(subtitle, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => Container(
                  margin: const EdgeInsets.all(4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton(
                onPressed: () {
                  if (_index < _slides.length - 1) {
                    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  } else {
                    context.go(RouteNames.login);
                  }
                },
                child: Text(_index < _slides.length - 1 ? 'Tiếp theo' : 'Bắt đầu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
