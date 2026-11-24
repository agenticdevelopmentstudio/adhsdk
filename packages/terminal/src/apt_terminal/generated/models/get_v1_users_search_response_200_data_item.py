from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.public_user_search_hit_kind import PublicUserSearchHitKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1UsersSearchResponse200DataItem")


@_attrs_define
class GetV1UsersSearchResponse200DataItem:
    """
    Attributes:
        slug (str):
        display_name (None | str):
        avatar_url (None | str):
        kind (PublicUserSearchHitKind):
        object_ (Literal['user'] | Unset):
    """

    slug: str
    display_name: None | str
    avatar_url: None | str
    kind: PublicUserSearchHitKind
    object_: Literal["user"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        display_name: None | str
        display_name = self.display_name

        avatar_url: None | str
        avatar_url = self.avatar_url

        kind = self.kind.value

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "display_name": display_name,
                "avatar_url": avatar_url,
                "kind": kind,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        def _parse_display_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        display_name = _parse_display_name(d.pop("display_name"))

        def _parse_avatar_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        avatar_url = _parse_avatar_url(d.pop("avatar_url"))

        kind = PublicUserSearchHitKind(d.pop("kind"))

        object_ = cast(Literal["user"] | Unset, d.pop("object", UNSET))
        if object_ != "user" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'user', got '{object_}'")

        get_v1_users_search_response_200_data_item = cls(
            slug=slug,
            display_name=display_name,
            avatar_url=avatar_url,
            kind=kind,
            object_=object_,
        )

        get_v1_users_search_response_200_data_item.additional_properties = d
        return get_v1_users_search_response_200_data_item

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
