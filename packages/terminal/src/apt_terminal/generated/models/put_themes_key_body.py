from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.put_themes_key_body_data import PutThemesKeyBodyData


T = TypeVar("T", bound="PutThemesKeyBody")


@_attrs_define
class PutThemesKeyBody:
    """
    Attributes:
        label (str | Unset):
        based_on (None | str | Unset):
        data (PutThemesKeyBodyData | Unset):
    """

    label: str | Unset = UNSET
    based_on: None | str | Unset = UNSET
    data: PutThemesKeyBodyData | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        label = self.label

        based_on: None | str | Unset
        if isinstance(self.based_on, Unset):
            based_on = UNSET
        else:
            based_on = self.based_on

        data: dict[str, Any] | Unset = UNSET
        if not isinstance(self.data, Unset):
            data = self.data.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if label is not UNSET:
            field_dict["label"] = label
        if based_on is not UNSET:
            field_dict["basedOn"] = based_on
        if data is not UNSET:
            field_dict["data"] = data

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.put_themes_key_body_data import PutThemesKeyBodyData

        d = dict(src_dict)
        label = d.pop("label", UNSET)

        def _parse_based_on(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        based_on = _parse_based_on(d.pop("basedOn", UNSET))

        _data = d.pop("data", UNSET)
        data: PutThemesKeyBodyData | Unset
        if isinstance(_data, Unset):
            data = UNSET
        else:
            data = PutThemesKeyBodyData.from_dict(_data)

        put_themes_key_body = cls(
            label=label,
            based_on=based_on,
            data=data,
        )

        put_themes_key_body.additional_properties = d
        return put_themes_key_body

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
