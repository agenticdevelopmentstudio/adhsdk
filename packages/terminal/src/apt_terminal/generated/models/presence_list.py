from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.presence_view import PresenceView


T = TypeVar("T", bound="PresenceList")


@_attrs_define
class PresenceList:
    """
    Attributes:
        presence (list[PresenceView]): One entry per requested id, in the order requested (duplicates included).
    """

    presence: list[PresenceView]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        presence = []
        for presence_item_data in self.presence:
            presence_item = presence_item_data.to_dict()
            presence.append(presence_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "presence": presence,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.presence_view import PresenceView

        d = dict(src_dict)
        presence = []
        _presence = d.pop("presence")
        for presence_item_data in _presence:
            presence_item = PresenceView.from_dict(presence_item_data)

            presence.append(presence_item)

        presence_list = cls(
            presence=presence,
        )

        presence_list.additional_properties = d
        return presence_list

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
