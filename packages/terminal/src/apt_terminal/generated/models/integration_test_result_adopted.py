from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.integration_test_result_adopted_connected_item import (
        IntegrationTestResultAdoptedConnectedItem,
    )
    from ..models.integration_test_result_adopted_skipped_item import (
        IntegrationTestResultAdoptedSkippedItem,
    )


T = TypeVar("T", bound="IntegrationTestResultAdopted")


@_attrs_define
class IntegrationTestResultAdopted:
    """GitHub App, saved config only. Testing a GitHub App IS adopting its installations — the only proof an app id and
    private key are real is to mint a JWT and enumerate what the app can see, and that enumeration is what creates the
    connections and warms the repository cache. So this field is the connect that just happened, reported.

        Attributes:
            connected (list[IntegrationTestResultAdoptedConnectedItem]):
            skipped (list[IntegrationTestResultAdoptedSkippedItem]):
    """

    connected: list[IntegrationTestResultAdoptedConnectedItem]
    skipped: list[IntegrationTestResultAdoptedSkippedItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        connected = []
        for connected_item_data in self.connected:
            connected_item = connected_item_data.to_dict()
            connected.append(connected_item)

        skipped = []
        for skipped_item_data in self.skipped:
            skipped_item = skipped_item_data.to_dict()
            skipped.append(skipped_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "connected": connected,
                "skipped": skipped,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.integration_test_result_adopted_connected_item import (
            IntegrationTestResultAdoptedConnectedItem,
        )
        from ..models.integration_test_result_adopted_skipped_item import (
            IntegrationTestResultAdoptedSkippedItem,
        )

        d = dict(src_dict)
        connected = []
        _connected = d.pop("connected")
        for connected_item_data in _connected:
            connected_item = IntegrationTestResultAdoptedConnectedItem.from_dict(
                connected_item_data
            )

            connected.append(connected_item)

        skipped = []
        _skipped = d.pop("skipped")
        for skipped_item_data in _skipped:
            skipped_item = IntegrationTestResultAdoptedSkippedItem.from_dict(skipped_item_data)

            skipped.append(skipped_item)

        integration_test_result_adopted = cls(
            connected=connected,
            skipped=skipped,
        )

        integration_test_result_adopted.additional_properties = d
        return integration_test_result_adopted

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
