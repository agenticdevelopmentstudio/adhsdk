from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.public_address import PublicAddress
    from ..models.public_persona_summary import PublicPersonaSummary
    from ..models.public_social_link import PublicSocialLink


T = TypeVar("T", bound="GetV1UsersResponse200")


@_attrs_define
class GetV1UsersResponse200:
    """
    Attributes:
        slug (str):
        display_name (None | str):
        avatar_url (None | str):
        created (int): Unix timestamp, in seconds.
        social_links (list[PublicSocialLink]):
        emails (list[str]):
        phones (list[str]):
        addresses (list[PublicAddress]):
        personas (list[PublicPersonaSummary]):
        object_ (Literal['user'] | Unset):
    """

    slug: str
    display_name: None | str
    avatar_url: None | str
    created: int
    social_links: list[PublicSocialLink]
    emails: list[str]
    phones: list[str]
    addresses: list[PublicAddress]
    personas: list[PublicPersonaSummary]
    object_: Literal["user"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        display_name: None | str
        display_name = self.display_name

        avatar_url: None | str
        avatar_url = self.avatar_url

        created = self.created

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

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "display_name": display_name,
                "avatar_url": avatar_url,
                "created": created,
                "social_links": social_links,
                "emails": emails,
                "phones": phones,
                "addresses": addresses,
                "personas": personas,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        display_name = _parse_display_name(d.pop("display_name"))

        def _parse_avatar_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        avatar_url = _parse_avatar_url(d.pop("avatar_url"))

        created = d.pop("created")

        social_links = []
        _social_links = d.pop("social_links")
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

        object_ = cast(Literal["user"] | Unset, d.pop("object", UNSET))
        if object_ != "user" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'user', got '{object_}'")

        get_v1_users_response_200 = cls(
            slug=slug,
            display_name=display_name,
            avatar_url=avatar_url,
            created=created,
            social_links=social_links,
            emails=emails,
            phones=phones,
            addresses=addresses,
            personas=personas,
            object_=object_,
        )

        get_v1_users_response_200.additional_properties = d
        return get_v1_users_response_200

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
