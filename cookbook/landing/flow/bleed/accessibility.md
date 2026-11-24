
Bleed itself renders a generic, role-less `div` and makes no accessibility-tree changes; assistive-technology behavior is otherwise inherited entirely from `children`. However, because the component's purpose is to let content run into a visually clipped page edge:

- **No essential content in the crop**: Content placed in the bled region SHOULD be decorative only. Because the overhang is cropped by the ancestor's `overflow-x: clip`, essential text or an interactive control placed there risks being visually cut off, even where it may remain present in the accessibility tree.

