# Layout 11 - Aurora Glass Style Guide

## Design Philosophy
Layout 11 implements the "Aurora Glass" design concept, combining 2025's trending glassmorphism with flowing aurora gradient backgrounds, creating a modern, ethereal interface that feels both premium and approachable.

## Color Palette

### Primary Colors
- **Aurora Purple**: `#7B3FF2` - Primary accent, CTAs, highlights
- **Aurora Blue**: `#3F7BF2` - Secondary actions, links
- **Aurora Pink**: `#F23FB7` - Tertiary elements, notifications
- **Aurora Green**: `#3FF27B` - Success states, positive feedback

### Background Colors
- **Glass White**: `rgba(255, 255, 255, 0.1)` - Glass panels in light mode
- **Glass Dark**: `rgba(18, 18, 32, 0.8)` - Glass panels in dark mode
- **Aurora Gradient**: Linear gradient from Aurora Purple to Aurora Blue to Aurora Pink
- **Pure White**: `#FFFFFF` - Light mode background
- **Deep Space**: `#121220` - Dark mode background

### Text Colors
- **Text Primary**: `#1A1A2E` - Main text in light mode
- **Text Secondary**: `#6B6B8A` - Secondary text in light mode
- **Text Primary Dark**: `#FFFFFF` - Main text in dark mode
- **Text Secondary Dark**: `#B8B8D0` - Secondary text in dark mode

### Status Colors
- **Success**: `#3FF27B` - Success messages, completed states
- **Warning**: `#FFB74D` - Warnings, alerts
- **Error**: `#FF6B6B` - Error messages, critical alerts
- **Info**: `#3F7BF2` - Information messages

## Typography

### Font Family
- **Primary**: `SF Pro Display` (iOS) / `Roboto` (Android)
- **Fallback**: System sans-serif fonts

### Font Weights
- **Light**: 300 - Subtle text, captions
- **Regular**: 400 - Body text, descriptions
- **Medium**: 500 - Emphasis, important text
- **Bold**: 700 - Headlines, CTAs
- **Black**: 900 - Hero text, major headlines

### Font Sizes
- **Hero**: 42px - Main dashboard title
- **H1**: 32px - Section headers
- **H2**: 24px - Card titles
- **H3**: 18px - Subsection headers
- **Body**: 16px - Main content text
- **Caption**: 14px - Secondary information
- **Micro**: 12px - Fine print, timestamps

## Visual Elements

### Glassmorphism
- **Blur Radius**: 20px - Background blur for glass effect
- **Transparency**: 0.1-0.3 - Varies by element importance
- **Border**: 1px solid rgba(255, 255, 255, 0.2) - Subtle glass borders
- **Shadow**: Soft shadows with 0.1-0.2 opacity for depth

### Border Radius
- **Small**: 8px - Buttons, small cards
- **Medium**: 16px - Cards, containers
- **Large**: 24px - Main panels, large cards
- **Full**: 50% - Circular elements, avatars

### Spacing
- **Micro**: 4px - Tight spacing, icon gaps
- **Small**: 8px - Related elements
- **Medium**: 16px - Standard component spacing
- **Large**: 24px - Section spacing
- **XLarge**: 32px - Major section breaks

## Interactive Elements

### Buttons
- **Primary**: Aurora Purple background, white text, 16px padding
- **Secondary**: Glass background with Aurora Blue border
- **Ghost**: Transparent with Aurora gradient text
- **Hover States**: Subtle scale (1.02) and shadow enhancement

### Animations
- **Micro-interactions**: 200-300ms ease-in-out transitions
- **Page Transitions**: 400ms smooth fades with slide effects
- **Loading States**: Aurora gradient shimmer effect
- **Success Feedback**: 500ms celebration animation with particles

### Haptic Feedback
- **Success**: Light impact on successful actions
- **Error**: Medium vibration on errors
- **Navigation**: Subtle feedback on tab switches

## Accessibility

### Contrast Ratios
- **Normal Text**: 4.5:1 minimum contrast ratio
- **Large Text**: 3:1 minimum contrast ratio
- **Interactive Elements**: 3:1 minimum contrast ratio

### Focus Indicators
- **Keyboard Navigation**: 2px Aurora Blue outline
- **Touch Targets**: Minimum 44px touch target size
- **Screen Reader**: Proper semantic labeling

### Responsive Design
- **Mobile First**: Designed for 320px minimum width
- **Tablet**: Optimized for 768px and up
- **Desktop**: Enhanced experience for 1024px and up

## Unique Features

### Aurora Background
Flowing gradient background that subtly shifts colors, creating an ethereal, premium feel without being distracting.

### Glass Cards
Semi-transparent cards that blur the background content, creating depth and hierarchy while maintaining content visibility.

### Soft Geometry
All elements use soft, rounded corners for approachability and modern aesthetics aligned with 2025 trends.

### Adaptive Color Scheme
Colors automatically adjust based on system theme (light/dark) and can be personalized based on user preferences.

## Implementation Notes
- Use Flutter's `BackdropFilter` for glassmorphism effects
- Implement smooth animations with `AnimationController`
- Ensure proper contrast in both light and dark modes
- Test on various device sizes for responsiveness
- Include haptic feedback for all interactive elements