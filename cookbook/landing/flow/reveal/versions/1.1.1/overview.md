
Reveal is a wrapper component that fades and lifts its children into place as they enter the viewport. It uses the Intersection Observer API to detect when the wrapped element becomes visible and transitions it from a hidden state to a visible state. The component preserves accessibility by rendering content in its visible (finished) state by default; JavaScript enhancements only apply the hidden state after the component mounts.

