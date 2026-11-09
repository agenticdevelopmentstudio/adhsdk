from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.public_user_search_hit_kind import PublicUserSearchHitKind

T = TypeVar("T", bound="PublicUserSearchHit")


@_attrs_define
class PublicUserSearchHit:
    """
    Attributes:
        slug (str):
        display_name (None | str):
        avatar_url (None | str):
        kind (PublicUserSearchHitKind):
    """

    slug: str
    display_name: None | str
    avatar_url: None | str
    kind: PublicUserSearchHitKind
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        display_name: None | str
        display_name = self.display_name

        avatar_url: None | str
        avatar_url = self.avatar_url

        kind = self.kind.value

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

        public_user_search_hit = cls(
            slug=slug,
            display_name=display_name,
            avatar_url=avatar_url,
            kind=kind,
        )

        public_user_search_hit.additional_properties = d
        return public_user_search_hit

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
