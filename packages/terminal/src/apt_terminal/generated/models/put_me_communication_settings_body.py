from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PutMeCommunicationSettingsBody")


@_attrs_define
class PutMeCommunicationSettingsBody:
    """
    Attributes:
        dm_audience_mask (int): AUDIENCE bitmask of who may DM the user (0 = nobody; default PUBLIC|HUB = 3)
        presence_audience_mask (int): AUDIENCE bitmask of who may see the user presence (0 = nobody; default PUBLIC|HUB
            = 3)
        appear_offline (bool): When true, presence is hidden from EVERYONE regardless of the mask
    """

    dm_audience_mask: int
    presence_audience_mask: int
    appear_offline: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        dm_audience_mask = self.dm_audience_mask

        presence_audience_mask = self.presence_audience_mask

        appear_offline = self.appear_offline

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "dmAudienceMask": dm_audience_mask,
                "presenceAudienceMask": presence_audience_mask,
                "appearOffline": appear_offline,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        dm_audience_mask = d.pop("dmAudienceMask")

        presence_audience_mask = d.pop("presenceAudienceMask")

        appear_offline = d.pop("appearOffline")

        put_me_communication_settings_body = cls(
            dm_audience_mask=dm_audience_mask,
            presence_audience_mask=presence_audience_mask,
            appear_offline=appear_offline,
        )

        put_me_communication_settings_body.additional_properties = d
        return put_me_communication_settings_body

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
