
ConnectorAnchor is a registration anchor for visual connectors that link UI elements across a multi-pane layout. The component renders as an invisible span that registers its DOM reference with a shared connector registry, enabling external connector logic to query anchor positions and draw lines or other visual connections between designated points. The component is not visible to end users or assistive technologies.

The connector registry is any object implementing the `ConnectorRegistry` contract (see [adhsdk.ingredient.chat.modes.three-pane.connectors.connector-registry](cookbook:e5b8e26f-2869-4a09-8d8e-0bb68ece805d)): `register(id: string, el: HTMLElement): () => void`. Every call to `register` returns a cleanup function that removes the entry when invoked; ConnectorAnchor relies on this to unregister unconditionally on unmount and on `id` change.

