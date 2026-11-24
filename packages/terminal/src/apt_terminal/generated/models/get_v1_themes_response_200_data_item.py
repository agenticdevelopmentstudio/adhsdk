from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.theme_data import ThemeData


T = TypeVar("T", bound="GetV1ThemesResponse200DataItem")


@_attrs_define
class GetV1ThemesResponse200DataItem:
    """
    Attributes:
        key (str):
        label (str):
        based_on (None | str):
        data (ThemeData):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['theme'] | Unset):
    """

    key: str
    label: str
    based_on: None | str
    data: ThemeData
    created: int
    updated: int
    object_: Literal["theme"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        label = self.label

        based_on: None | str
        based_on = self.based_on

        data = self.data.to_dict()

        created = self.created

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "label": label,
                "based_on": based_on,
                "data": data,
                "created": created,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.theme_data import ThemeData

        d = dict(src_dict)
        key = d.pop("key")

        label = d.pop("label")

        def _parse_based_on(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        based_on = _parse_based_on(d.pop("based_on"))

        data = ThemeData.from_dict(d.pop("data"))

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["theme"] | Unset, d.pop("object", UNSET))
        if object_ != "theme" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'theme', got '{object_}'")

        get_v1_themes_response_200_data_item = cls(
            key=key,
            label=label,
            based_on=based_on,
            data=data,
            created=created,
            updated=updated,
            object_=object_,
        )

        get_v1_themes_response_200_data_item.additional_properties = d
        return get_v1_themes_response_200_data_item

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
