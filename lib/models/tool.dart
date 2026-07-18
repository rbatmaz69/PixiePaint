enum ToolKind { brush, marker, crayon, eraser, fill }

/// Base stroke widths in canvas units (canvas is 2048 px wide).
const List<double> kBrushSizes = [14, 28, 56];

const int kFillTolerance = 32;
