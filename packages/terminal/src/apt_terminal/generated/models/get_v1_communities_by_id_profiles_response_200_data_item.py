from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1CommunitiesByIdProfilesResponse200DataItem")


@_attrs_define
class GetV1CommunitiesByIdProfilesResponse200DataItem:
    """
    Attributes:
        customer_id (str):
        slug (str):
        avatar_url (str):
        display_name (None | str | Unset):
        object_ (Literal['profile'] | Unset):
    """

    customer_id: str
    slug: str
    avatar_url: str
    display_name: None | str | Unset = UNSET
    object_: Literal["profile"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        customer_id = self.customer_id

        slug = self.slug

        avatar_url = self.avatar_url

        display_name: None | str | Unset
        if isinstance(self.display_name, Unset):
            display_name = UNSET
        else:
            display_name = self.display_name

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "customer_id": customer_id,
                "slug": slug,
                "avatar_url": avatar_url,
            }
        )
        if display_name is not UNSET:
            field_dict["display_name"] = display_name
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        customer_id = d.pop("customer_id")

        slug = d.pop("slug")

        avatar_url = d.pop("avatar_url")

        def _parse_display_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        display_name = _parse_display_name(d.pop("display_name", UNSET))

        object_ = cast(Literal["profile"] | Unset, d.pop("object", UNSET))
        if object_ != "profile" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'profile', got '{object_}'")

        get_v1_communities_by_id_profiles_response_200_data_item = cls(
            customer_id=customer_id,
            slug=slug,
            avatar_url=avatar_url,
            display_name=display_name,
            object_=object_,
        )

        get_v1_communities_by_id_profiles_response_200_data_item.additional_properties = d
        return get_v1_communities_by_id_profiles_response_200_data_item

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
