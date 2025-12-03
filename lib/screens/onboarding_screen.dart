import 'package:flutter/material.dart';
import 'package:payhive/widgets/on_boarding_widget.dart';
import 'package:payhive/widgets/primary_button_widget.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'signin_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool isLastPage = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  isLastPage = (index == 3);
                });
              },
              children: const [
                OnBoardingWidget(
                  image: 'assets/images/on_boarding_images/welcomeImg.png',
                  title: 'Welcome to PayHive',
                  subtitle: 'Your smart and secure digital wallet.',
                ),
                OnBoardingWidget(
                  image: 'assets/images/on_boarding_images/transationImg.png',
                  title: 'Send Money Instantly',
                  subtitle:
                      'Fast transfers, QR payments, and utilities in one place.',
                ),
                OnBoardingWidget(
                  image: 'assets/images/on_boarding_images/securityImg.png',
                  title: 'Smarter Payment Protection',
                  subtitle:
                      'Get alerts for unusual amounts before transferring.',
                ),
                OnBoardingWidget(
                  image: 'assets/images/on_boarding_images/refundImg.png',
                  title: 'Undo Accidental Payments',
                  subtitle: 'Request refunds with approval from the receiver.',
                ),
              ],
            ),

            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),

                child: isLastPage
                    ? PrimaryButtonWidget(
                        text: "Get Started",
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SigninScreen(),
                            ),
                          );
                        },
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                3,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Text(
                              "Skip",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          SmoothPageIndicator(
                            controller: _pageController,
                            count: 4,
                            effect: ExpandingDotsEffect(
                              activeDotColor: Color(0xFFFF6B00),
                              dotColor: Colors.grey,
                              dotHeight: 8,
                              dotWidth: 8,
                              expansionFactor: 3,
                            ),
                          ),

                          GestureDetector(
                            onTap: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: const Text(
                              "Next",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFFF6B00),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
