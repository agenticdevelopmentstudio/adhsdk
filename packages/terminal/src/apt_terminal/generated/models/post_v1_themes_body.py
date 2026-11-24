from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_themes_body_data import PostV1ThemesBodyData


T = TypeVar("T", bound="PostV1ThemesBody")


@_attrs_define
class PostV1ThemesBody:
    """
    Attributes:
        key (str): DNS-ish slug, unique among live themes
        label (str):
        data (PostV1ThemesBodyData):
        based_on (None | str | Unset): the seed theme key this derives from
    """

    key: str
    label: str
    data: PostV1ThemesBodyData
    based_on: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        label = self.label

        data = self.data.to_dict()

        based_on: None | str | Unset
        if isinstance(self.based_on, Unset):
            based_on = UNSET
        else:
            based_on = self.based_on

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "label": label,
                "data": data,
            }
        )
        if based_on is not UNSET:
            field_dict["based_on"] = based_on

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_themes_body_data import PostV1ThemesBodyData

        d = dict(src_dict)
        key = d.pop("key")

        label = d.pop("label")

        data = PostV1ThemesBodyData.from_dict(d.pop("data"))

        def _parse_based_on(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        based_on = _parse_based_on(d.pop("based_on", UNSET))

        post_v1_themes_body = cls(
            key=key,
            label=label,
            data=data,
            based_on=based_on,
        )

        post_v1_themes_body.additional_properties = d
        return post_v1_themes_body

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
