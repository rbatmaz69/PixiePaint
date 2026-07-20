enum ToolKind {
  brush,
  marker,
  crayon,
  rainbow,
  glitter,
  neon,
  eraser,
  fill,
  stamp,
  eyedropper,
  shape,
}

/// Drag-to-draw shape motifs for [ToolKind.shape].
enum ShapeKind { circle, square, heart, star, rainbow }

/// Base stroke widths in canvas units (canvas is 2048 px wide). These are
/// the S/M/L quick presets; the slider covers the full range below.
const List<double> kBrushSizes = [14, 28, 56];

const double kMinBrushSize = 8;
const double kMaxBrushSize = 90;

/// Stamp size derived from the continuous brush size — the medium preset
/// (28) maps to the classic medium stamp (220 canvas px).
double stampSizeFor(double brushSize) =>
    (brushSize * 220 / 28).clamp(90.0, 420.0);

const int kFillTolerance = 32;
