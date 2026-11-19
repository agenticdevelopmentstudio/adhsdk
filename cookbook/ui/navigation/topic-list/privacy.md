
- **Data collected**: None by the component itself - it only renders
  caller-supplied item/section values for display.
- **Storage**: In-memory only, for the component's lifetime; nothing is
  written to disk or a settings store by this component. The one exception
  is a drag: dragging an item row writes the string the caller's
  drag-payload provider returned to the system drag pasteboard, under the
  component's item pasteboard type. The payload is entirely caller-chosen;
  with no provider set nothing is written.
- **Transmission**: No networking call appears anywhere in source. A
  dragged payload sits on the system drag pasteboard, which is shared
  across processes rather than private to this component; the component
  sets drag operations only for drops within the same application and
  leaves the operations for other applications at the platform default.
- **Retention**: None beyond the component's lifetime; state is discarded
  when the component is deallocated.

