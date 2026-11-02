from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.public_address import PublicAddress
    from ..models.public_persona_summary import PublicPersonaSummary
    from ..models.public_social_link import PublicSocialLink


T = TypeVar("T", bound="PublicUserProfile")


@_attrs_define
class PublicUserProfile:
    """
    Attributes:
        slug (str):
        display_name (None | str):
        avatar_url (None | str):
        created_at (str):
        social_links (list[PublicSocialLink]):
        emails (list[str]):
        phones (list[str]):
        addresses (list[PublicAddress]):
        personas (list[PublicPersonaSummary]):
    """

    slug: str
    display_name: None | str
    avatar_url: None | str
    created_at: str
    social_links: list[PublicSocialLink]
    emails: list[str]
    phones: list[str]
    addresses: list[PublicAddress]
    personas: list[PublicPersonaSummary]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        display_name: None | str
        display_name = self.display_name

        avatar_url: None | str
        avatar_url = self.avatar_url

        created_at = self.created_at

        social_links = []
        for social_links_item_data in self.social_links:
            social_links_item = social_links_item_data.to_dict()
            social_links.append(social_links_item)

        emails = self.emails

        phones = self.phones

        addresses = []
        for addresses_item_data in self.addresses:
            addresses_item = addresses_item_data.to_dict()
            addresses.append(addresses_item)

        personas = []
        for personas_item_data in self.personas:
            personas_item = personas_item_data.to_dict()
            personas.append(personas_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "displayName": display_name,
                "avatarUrl": avatar_url,
                "createdAt": created_at,
                "socialLinks": social_links,
                "emails": emails,
                "phones": phones,
                "addresses": addresses,
                "personas": personas,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.public_address import PublicAddress
        from ..models.public_persona_summary import PublicPersonaSummary
        from ..models.public_social_link import PublicSocialLink

        d = dict(src_dict)
        slug = d.pop("slug")

        def _parse_display_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        display_name = _parse_display_name(d.pop("displayName"))

        def _parse_avatar_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        avatar_url = _parse_avatar_url(d.pop("avatarUrl"))

        created_at = d.pop("createdAt")

        social_links = []
        _social_links = d.pop("socialLinks")
        for social_links_item_data in _social_links:
            social_links_item = PublicSocialLink.from_dict(social_links_item_data)

            social_links.append(social_links_item)

        emails = cast(list[str], d.pop("emails"))

        phones = cast(list[str], d.pop("phones"))

        addresses = []
        _addresses = d.pop("addresses")
        for addresses_item_data in _addresses:
            addresses_item = PublicAddress.from_dict(addresses_item_data)

            addresses.append(addresses_item)

        personas = []
        _personas = d.pop("personas")
        for personas_item_data in _personas:
            personas_item = PublicPersonaSummary.from_dict(personas_item_data)

            personas.append(personas_item)

        public_user_profile = cls(
            slug=slug,
            display_name=display_name,
            avatar_url=avatar_url,
            created_at=created_at,
            social_links=social_links,
            emails=emails,
            phones=phones,
            addresses=addresses,
            personas=personas,
        )

        public_user_profile.additional_properties = d
        return public_user_profile

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
