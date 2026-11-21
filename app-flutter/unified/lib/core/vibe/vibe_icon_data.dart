// GERADO a partir de layout-app/vibe-5-definitivas.html (sprites do protótipo).
// Não editar à mão: os traços precisam ser idênticos aos do layout aprovado.
import 'dart:ui' show Color;

import 'vibe_icon_part.dart';

/// Ícones de traço 24×24 do layout (sprite principal, g-* e i-* da tela Dock).
const Map<String, List<VibeIconPart>> vibeIconData = {
  'alert': [VibeIconPart('M12 4 2.5 20h19zM12 10v5M12 17.5h.01')],
  'arr': [VibeIconPart('M7 17 17 7M9 7h8v8')],
  'bar': [VibeIconPart('M3 5v14M6 5v14M10 5v14M13 5v14M17 5v14M21 5v14')],
  'bell': [
    VibeIconPart(
        'M6 8a6 6 0 0 1 12 0c0 7 3 8 3 8H3s3-1 3-8M10 20a2 2 0 0 0 4 0')
  ],
  'bolt': [VibeIconPart('M13 2 4 14h7l-1 8 9-12h-7z')],
  'cal': [VibeIconPart('M4 6h16v15H4zM4 10h16M8 3v4M16 3v4')],
  'cell': [VibeIconPart('M5 19v-3M10 19v-6M15 19v-9M20 19V5')],
  'chat': [VibeIconPart('M4 5h16v11H9l-5 4z')],
  'check': [VibeIconPart('M5 12.5l4.5 4.5L19 7.5')],
  'chev': [VibeIconPart('M9 5l7 7-7 7')],
  'chevd': [VibeIconPart('M6 9l6 6 6-6')],
  'clock': [VibeIconPart('M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18M12 7v5l3 2')],
  'copy': [VibeIconPart('M9 9h11v11H9zM5 15H4V4h11v1')],
  'doc': [VibeIconPart('M6 3h9l4 4v14H6zM14 3v5h5M9 13h7M9 17h5')],
  'down': [VibeIconPart('M12 4v11M7 10l5 5 5-5M5 20h14')],
  'eye': [
    VibeIconPart(
        'M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6')
  ],
  'file': [VibeIconPart('M5 3h14v18l-3-2-2 2-2-2-2 2-2-2-3 2zM9 8h6M9 12h6')],
  'g-chart': [VibeIconPart('M4 20V10M10 20V4M16 20v-7M22 20H2')],
  'g-help': [
    VibeIconPart('M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0z'),
    VibeIconPart('M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.7.3-1 .9-1 1.6v.6M12 17h.01')
  ],
  'g-mail': [
    VibeIconPart(
        'M5 5h14a2 2 0 0 1 2 2v10a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-10a2 2 0 0 1 2 -2z'),
    VibeIconPart('m3 7 9 6 9-6')
  ],
  'g-out': [
    VibeIconPart(
        'M15 4h3a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-3M10 17l-5-5 5-5M5 12h11')
  ],
  'g-phone': [
    VibeIconPart(
        'M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z')
  ],
  'g-play': [VibeIconPart('M7 5v14l11-7z')],
  'g-refresh': [VibeIconPart('M20 11a8 8 0 1 0-2.3 5.7M20 4v7h-7')],
  'g-route': [
    VibeIconPart('M4 18a2 2 0 1 0 4 0a2 2 0 1 0 -4 0z'),
    VibeIconPart('M16 6a2 2 0 1 0 4 0a2 2 0 1 0 -4 0z'),
    VibeIconPart('M8 18h7a3 3 0 0 0 0-6H9a3 3 0 0 1 0-6h7')
  ],
  'g-shield': [VibeIconPart('M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6z')],
  'g-star': [
    VibeIconPart(
        'm12 3 2.7 5.6 6.1.9-4.4 4.3 1 6.1L12 17l-5.5 2.9 1-6.1L3.2 9.5l6.1-.9z')
  ],
  'g-stop': [
    VibeIconPart(
        'M8 6h8a2 2 0 0 1 2 2v8a2 2 0 0 1 -2 2h-8a2 2 0 0 1 -2 -2v-8a2 2 0 0 1 2 -2z')
  ],
  'g-trophy': [
    VibeIconPart(
        'M8 4h8v5a4 4 0 0 1-8 0zM8 6H5a3 3 0 0 0 3 4M16 6h3a3 3 0 0 1-3 4M12 13v4M8 20h8M10 17h4')
  ],
  'g-x': [VibeIconPart('M6 6l12 12M18 6 6 18')],
  'gauge': [VibeIconPart('M4 17a9 9 0 1 1 16 0M12 13l4-5M12 13h.01')],
  'gear': [
    VibeIconPart(
        'M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1')
  ],
  'gift': [
    VibeIconPart(
        'M4 11h16v9H4zM3 7h18v4H3zM12 7v13M12 7C10.5 4 7 3.5 7 5.8 7 7 9 7 12 7c3 0 5 0 5-1.2C17 3.5 13.5 4 12 7')
  ],
  'globe': [
    VibeIconPart(
        'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18M3 12h18M12 3c2.5 2.6 3.8 5.6 3.8 9s-1.3 6.4-3.8 9c-2.5-2.6-3.8-5.6-3.8-9S9.5 5.6 12 3')
  ],
  'grid': [VibeIconPart('M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h6v6h-6z')],
  'home': [
    VibeIconPart(
        'M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z')
  ],
  'i-arrow': [VibeIconPart('M4 12h15m-6-6 6 6-6 6')],
  'i-bars': [
    VibeIconPart('M3 17.5v-2.2m5.5 2.2v-5.7m5.5 5.7v-9m5.5 9V5',
        strokeWidth: 3.1)
  ],
  'i-battery': [
    VibeIconPart(
        'M3.8 7h13.4a2.3 2.3 0 0 1 2.3 2.3v5.4a2.3 2.3 0 0 1 -2.3 2.3h-13.4a2.3 2.3 0 0 1 -2.3 -2.3v-5.4a2.3 2.3 0 0 1 2.3 -2.3z'),
    VibeIconPart('M22 10v4'),
    VibeIconPart(
        'M4.8 9.3h11.2a0.8 0.8 0 0 1 0.8 0.8v3.8a0.8 0.8 0 0 1 -0.8 0.8h-11.2a0.8 0.8 0 0 1 -0.8 -0.8v-3.8a0.8 0.8 0 0 1 0.8 -0.8z',
        fill: true,
        stroke: false)
  ],
  'i-bell': [
    VibeIconPart(
        'M5.3 15.4c1-1 1.3-2.2 1.3-5.1a5.4 5.4 0 0 1 10.8 0c0 2.9.3 4.1 1.3 5.1l1.1 1.6H4.2zM10 20a2.4 2.4 0 0 0 4 0')
  ],
  'i-bill': [
    VibeIconPart(
        'M5 3l2 1.5L9 3l3 1.5L15 3l2 1.5L19 3v18l-2-1.5-2 1.5-3-1.5L9 21l-2-1.5L5 21z'),
    VibeIconPart('M8.5 8.5h7m-7 4h7m-7 4h4')
  ],
  'i-boleto': [
    VibeIconPart('M3 6v12m3-12v12m3-12v12m4-12v12m2-12v12m4-12v12m2-12v12')
  ],
  'i-calendar': [
    VibeIconPart(
        'M6 5h12a3 3 0 0 1 3 3v10a3 3 0 0 1 -3 3h-12a3 3 0 0 1 -3 -3v-10a3 3 0 0 1 3 -3z'),
    VibeIconPart('M7.5 3v4m9-4v4M3 10h18M7 14h2m3 0h2m-7 4h2')
  ],
  'i-chat': [
    VibeIconPart(
        'M20.5 11.5a8.5 8.5 0 0 1-8.5 8.5h-1L5 22l.6-4.4A8.4 8.4 0 0 1 3.5 12 8.5 8.5 0 0 1 12 3a8.5 8.5 0 0 1 8.5 8.5Z'),
    VibeIconPart('M8 10h8m-8 4h5')
  ],
  'i-check': [VibeIconPart('m4 12 5 5L20 6')],
  'i-clock': [
    VibeIconPart('M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0z'),
    VibeIconPart('M12 7v5l3.5 2')
  ],
  'i-close': [VibeIconPart('m6 6 12 12M18 6 6 18')],
  'i-compare': [
    VibeIconPart(
        'M4.3 5h3.9a1.8 1.8 0 0 1 1.8 1.8v10.4a1.8 1.8 0 0 1 -1.8 1.8h-3.9a1.8 1.8 0 0 1 -1.8 -1.8v-10.4a1.8 1.8 0 0 1 1.8 -1.8z'),
    VibeIconPart(
        'M15.8 5h3.9a1.8 1.8 0 0 1 1.8 1.8v10.4a1.8 1.8 0 0 1 -1.8 1.8h-3.9a1.8 1.8 0 0 1 -1.8 -1.8v-10.4a1.8 1.8 0 0 1 1.8 -1.8z')
  ],
  'i-contract': [
    VibeIconPart('M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z'),
    VibeIconPart('M14 3v6h6M8 13h7m-7 4h5')
  ],
  'i-copy': [
    VibeIconPart(
        'M10 8h8.5a2 2 0 0 1 2 2v9a2 2 0 0 1 -2 2h-8.5a2 2 0 0 1 -2 -2v-9a2 2 0 0 1 2 -2z'),
    VibeIconPart('M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3')
  ],
  'i-diagonal': [VibeIconPart('M6 18 18 6M7 6h11v11')],
  'i-docs': [
    VibeIconPart(
        'M7 3h10a2 2 0 0 1 2 2v12M5 7h9a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2z'),
    VibeIconPart('M6.5 12h6m-6 4h4')
  ],
  'i-down': [VibeIconPart('m6 9 6 6 6-6')],
  'i-expand': [VibeIconPart('M14 4h6v6m0-6-7 7M10 20H4v-6m0 6 7-7')],
  'i-eye': [
    VibeIconPart('M2 12s3.8-7 10-7 10 7 10 7-3.8 7-10 7S2 12 2 12Z'),
    VibeIconPart('M9.3 12a2.7 2.7 0 1 0 5.4 0a2.7 2.7 0 1 0 -5.4 0z')
  ],
  'i-folder': [
    VibeIconPart(
        'M3 7a2 2 0 0 1 2-2h5l2 3h7a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z')
  ],
  'i-grid': [
    VibeIconPart(
        'M5.2 3.5h3.1a1.7 1.7 0 0 1 1.7 1.7v3.1a1.7 1.7 0 0 1 -1.7 1.7h-3.1a1.7 1.7 0 0 1 -1.7 -1.7v-3.1a1.7 1.7 0 0 1 1.7 -1.7z'),
    VibeIconPart(
        'M15.7 3.5h3.1a1.7 1.7 0 0 1 1.7 1.7v3.1a1.7 1.7 0 0 1 -1.7 1.7h-3.1a1.7 1.7 0 0 1 -1.7 -1.7v-3.1a1.7 1.7 0 0 1 1.7 -1.7z'),
    VibeIconPart(
        'M5.2 14h3.1a1.7 1.7 0 0 1 1.7 1.7v3.1a1.7 1.7 0 0 1 -1.7 1.7h-3.1a1.7 1.7 0 0 1 -1.7 -1.7v-3.1a1.7 1.7 0 0 1 1.7 -1.7z'),
    VibeIconPart(
        'M15.7 14h3.1a1.7 1.7 0 0 1 1.7 1.7v3.1a1.7 1.7 0 0 1 -1.7 1.7h-3.1a1.7 1.7 0 0 1 -1.7 -1.7v-3.1a1.7 1.7 0 0 1 1.7 -1.7z')
  ],
  'i-help': [
    VibeIconPart('M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0z'),
    VibeIconPart('M9 9a3 3 0 1 1 5 2.3c-1.5.9-2 1.5-2 2.7m0 3h.01')
  ],
  'i-history': [VibeIconPart('M3.3 10a8.8 8.8 0 1 1 .7 6M3 4v6h6m3-3v5l3 2')],
  'i-home': [
    VibeIconPart('m3 10 9-7 9 7v10a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1z')
  ],
  'i-house': [VibeIconPart('m2 10 10-7 10 7M5 9v11h14V9m-9 11v-7h4v7')],
  'i-inbox': [
    VibeIconPart(
        'm3 13 3-9h12l3 9v6a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1zM3 13h5l2 3h4l2-3h5')
  ],
  'i-key': [
    VibeIconPart('M3 9a5 5 0 1 0 10 0a5 5 0 1 0 -10 0z'),
    VibeIconPart(
        'm11.7 12.6 7.7 7.7 2-2-2-2 1-1-2.8-2.8-1 1-2.8-2.8M7.4 8.3h.01')
  ],
  'i-layers': [
    VibeIconPart('m2.5 8 9.5-5 9.5 5-9.5 5zM3 12l9 5 9-5M3 16l9 5 9-5')
  ],
  'i-left': [VibeIconPart('m14.5 5-7 7 7 7')],
  'i-mail': [
    VibeIconPart(
        'M5 5h14a2.5 2.5 0 0 1 2.5 2.5v9a2.5 2.5 0 0 1 -2.5 2.5h-14a2.5 2.5 0 0 1 -2.5 -2.5v-9a2.5 2.5 0 0 1 2.5 -2.5z'),
    VibeIconPart('m4 7 8 6 8-6')
  ],
  'i-pin': [
    VibeIconPart(
        'M19.5 10c0 5.2-7.5 11-7.5 11s-7.5-5.8-7.5-11a7.5 7.5 0 1 1 15 0z'),
    VibeIconPart('M9.6 10a2.4 2.4 0 1 0 4.8 0a2.4 2.4 0 1 0 -4.8 0z')
  ],
  'i-pix': [
    VibeIconPart(
        'M10.4 2.2a2.25 2.25 0 0 1 3.2 0l5.1 5.1h-2.9c-.6 0-1.1.2-1.5.6L12 10.2 9.7 7.9a2.1 2.1 0 0 0-1.5-.6H5.3zM5.3 16.7h2.9c.6 0 1.1-.2 1.5-.6l2.3-2.3 2.3 2.3c.4.4.9.6 1.5.6h2.9l-5.1 5.1a2.25 2.25 0 0 1-3.2 0z',
        fill: true,
        stroke: false),
    VibeIconPart(
        'm2.2 10.4 1.6-1.6h4.4c.2 0 .4.1.6.3l2.4 2.4a1.1 1.1 0 0 0 1.6 0l2.4-2.4c.2-.2.4-.3.6-.3h4.4l1.6 1.6a2.25 2.25 0 0 1 0 3.2l-1.6 1.6h-4.4c-.2 0-.4-.1-.6-.3l-2.4-2.4a1.1 1.1 0 0 0-1.6 0l-2.4 2.4c-.2.2-.4.3-.6.3H3.8l-1.6-1.6a2.25 2.25 0 0 1 0-3.2z',
        fill: true,
        stroke: false)
  ],
  'i-plus': [VibeIconPart('M12 4v16M4 12h16')],
  'i-pulse': [VibeIconPart('M2 12h5l3-7 4 14 3-7h5')],
  'i-right': [VibeIconPart('m9.5 5 7 7-7 7')],
  'i-ring': [
    VibeIconPart('M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0z'),
    VibeIconPart('M8 12a4 4 0 1 0 8 0a4 4 0 1 0 -8 0z'),
    VibeIconPart(
        'm5.5 5.5 3.7 3.7m5.6 5.6 3.7 3.7m0-13-3.7 3.7m-5.6 5.6-3.7 3.7')
  ],
  'i-save': [VibeIconPart('M6 4a1 1 0 0 1 1-1h10a1 1 0 0 1 1 1v17l-6-4-6 4z')],
  'i-search': [
    VibeIconPart('M4 10.5a6.5 6.5 0 1 0 13 0a6.5 6.5 0 1 0 -13 0z'),
    VibeIconPart('m16 16 5 5')
  ],
  'i-sliders': [
    VibeIconPart('M3 7h8m5 0h5M3 17h3m5 0h10'),
    VibeIconPart('M11 7a2.5 2.5 0 1 0 5 0a2.5 2.5 0 1 0 -5 0z'),
    VibeIconPart('M6 17a2.5 2.5 0 1 0 5 0a2.5 2.5 0 1 0 -5 0z')
  ],
  'i-sound': [VibeIconPart('M3 10v4m4-7v10m5-14v18m5-15v12m4-8v4')],
  'i-speed': [
    VibeIconPart('M3 17a9 9 0 1 1 18 0M12 15l5-5M4 17h2m12 0h2'),
    VibeIconPart('M10.5 16a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0 -3 0z')
  ],
  'i-stamp': [
    VibeIconPart(
        'M8 4a4 4 0 0 1 8 0c0 3-2 5-2 8h3l3 3v3H4v-3l3-3h3c0-3-2-5-2-8zM4 21h16')
  ],
  'i-support': [
    VibeIconPart('M4 13v-2a8 8 0 0 1 16 0v3m-3 5c-.5 1.3-1.7 2-4 2h-2'),
    VibeIconPart(
        'M4.8 11h0.9a1.8 1.8 0 0 1 1.8 1.8v3.4a1.8 1.8 0 0 1 -1.8 1.8h-0.9a1.8 1.8 0 0 1 -1.8 -1.8v-3.4a1.8 1.8 0 0 1 1.8 -1.8z'),
    VibeIconPart(
        'M18.3 11h0.9a1.8 1.8 0 0 1 1.8 1.8v3.4a1.8 1.8 0 0 1 -1.8 1.8h-0.9a1.8 1.8 0 0 1 -1.8 -1.8v-3.4a1.8 1.8 0 0 1 1.8 -1.8z')
  ],
  'i-tickets': [
    VibeIconPart(
        'M3 6h18v4a2 2 0 0 0 0 4v4H3v-4a2 2 0 0 0 0-4zM9 7v2m0 3v2m0 2v1')
  ],
  'i-user': [
    VibeIconPart('M8.3 8a3.7 3.7 0 1 0 7.4 0a3.7 3.7 0 1 0 -7.4 0z'),
    VibeIconPart('M4.5 20c.5-4 3.1-6 7.5-6s7 2 7.5 6')
  ],
  'i-wallet': [
    VibeIconPart(
        'M4 7V5l12-2v4M5 7h14a1.5 1.5 0 0 1 1.5 1.5V19a1.5 1.5 0 0 1-1.5 1.5H5A2 2 0 0 1 3 18.5V9a2 2 0 0 1 2-2z'),
    VibeIconPart('M21 11h-5v5h5')
  ],
  'i-wifi': [
    VibeIconPart(
        'M2 8.7a16 16 0 0 1 20 0M5.5 12a10.5 10.5 0 0 1 13 0m-9.5 3.3a5.5 5.5 0 0 1 6 0'),
    VibeIconPart('M11 19a1 1 0 1 0 2 0a1 1 0 1 0 -2 0z', fill: true)
  ],
  'info': [
    VibeIconPart('M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18M12 11v5M12 7.5h.01')
  ],
  'lock': [VibeIconPart('M6 11h12v9H6zM9 11V8a3 3 0 0 1 6 0v3')],
  'menu': [VibeIconPart('M4 7h16M4 12h16M4 17h10')],
  'more': [VibeIconPart('M5 12h.01M12 12h.01M19 12h.01')],
  'pix': [
    VibeIconPart(
        'M12 2.8 21.2 12 12 21.2 2.8 12zM7.6 7.6l4.4 4.4 4.4-4.4M7.6 16.4l4.4-4.4 4.4 4.4')
  ],
  'plus': [VibeIconPart('M12 5v14M5 12h14')],
  'pulse': [VibeIconPart('M3 12h4l2.5-6 5 12 2.5-6h4')],
  'router': [
    VibeIconPart(
        'M4 14h16v5H4zM7.5 16.5h.01M11 16.5h.01M16 14V9M13 7a4 4 0 0 1 6 0')
  ],
  'search': [VibeIconPart('M11 4a7 7 0 1 0 0 14 7 7 0 0 0 0-14M20 20l-4-4')],
  'share': [VibeIconPart('M12 3v12M8 7l4-4 4 4M5 13v7h14v-7')],
  'tag': [VibeIconPart('M3 12V4h8l10 10-8 8zM7.5 8.5h.01')],
  'unlock': [VibeIconPart('M6 11h12v9H6zM9 11V8a3 3 0 0 1 5.8-1')],
  'user': [
    VibeIconPart('M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8M4 21a8 8 0 0 1 16 0')
  ],
  'vibe': [VibeIconPart('M5 7.5l7 10 7-10')],
  'wa': [
    VibeIconPart(
        'M4 20l1.4-4.2A8.2 8.2 0 1 1 8.6 19zM9 8.6c0 3.4 2.9 6.4 6.4 6.4l1.2-1.6-2.2-1.2-1.1 1a5 5 0 0 1-2.5-2.5l1-1.1-1.2-2.2z')
  ],
  'wifi': [
    VibeIconPart(
        'M2 8.8a15 15 0 0 1 20 0M5 12.5a10.5 10.5 0 0 1 14 0M8.5 16a6 6 0 0 1 7 0M12 19.5h.01')
  ],
};

/// Ilustrações 120×120 dos cartões de oferta (PRI no protótipo).
const Map<String, List<VibeIconPart>> vibeArtData = {
  'gift': [
    VibeIconPart('M26 72a46 46 0 1 0 92 0a46 46 0 1 0 -92 0z',
        fill: true, stroke: false, opacity: 0.12),
    VibeIconPart(
        'M48 66h48a6 6 0 0 1 6 6v24a6 6 0 0 1 -6 6h-48a6 6 0 0 1 -6 -6v-24a6 6 0 0 1 6 -6z',
        fill: true,
        stroke: false,
        opacity: 0.85),
    VibeIconPart(
        'M43 52h58a5 5 0 0 1 5 5v7a5 5 0 0 1 -5 5h-58a5 5 0 0 1 -5 -5v-7a5 5 0 0 1 5 -5z',
        fill: true,
        stroke: false),
    VibeIconPart('M72 52v50',
        strokeWidth: 6.0, roundCap: false, color: Color(0xFFFFFFFF)),
    VibeIconPart(
        'M72 52c-5-13-23-16-23-6 0 7 13 6 23 6zM72 52c5-13 23-16 23-6 0 7-13 6-23 6z',
        strokeWidth: 5.0,
        roundCap: false)
  ],
  'turbo': [
    VibeIconPart('M26 72a46 46 0 1 0 92 0a46 46 0 1 0 -92 0z',
        fill: true, stroke: false, opacity: 0.12),
    VibeIconPart('M38 80a34 34 0 0 1 68 0', strokeWidth: 9.0, opacity: 0.32),
    VibeIconPart('M38 80a34 34 0 0 1 50-30', strokeWidth: 9.0),
    VibeIconPart('M72 80 93 57', strokeWidth: 6.0),
    VibeIconPart('M65 80a7 7 0 1 0 14 0a7 7 0 1 0 -14 0z',
        fill: true, stroke: false)
  ],
  'wifi': [
    VibeIconPart('M26 72a46 46 0 1 0 92 0a46 46 0 1 0 -92 0z',
        fill: true, stroke: false, opacity: 0.14),
    VibeIconPart('M50 56a31 31 0 0 1 44 0M58 65a18 18 0 0 1 28 0',
        strokeWidth: 6.0),
    VibeIconPart('M52 78V68M92 78V68', strokeWidth: 5.0),
    VibeIconPart(
        'M48 76h48a8 8 0 0 1 8 8v8a8 8 0 0 1 -8 8h-48a8 8 0 0 1 -8 -8v-8a8 8 0 0 1 8 -8z',
        fill: true,
        stroke: false),
    VibeIconPart('M51 88a3 3 0 1 0 6 0a3 3 0 1 0 -6 0z',
        fill: true, stroke: false, color: Color(0xFF15171C)),
    VibeIconPart('M61 88a3 3 0 1 0 6 0a3 3 0 1 0 -6 0z',
        fill: true, stroke: false, color: Color(0xFF15171C))
  ],
};
