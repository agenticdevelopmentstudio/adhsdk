from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.public_persona_summary_visibility import PublicPersonaSummaryVisibility

if TYPE_CHECKING:
    from ..models.public_owner_type_0 import PublicOwnerType0


T = TypeVar("T", bound="PublicPersonaSummary")


@_attrs_define
class PublicPersonaSummary:
    """
    Attributes:
        slug (str):
        name (str):
        description (None | str):
        visibility (PublicPersonaSummaryVisibility):
        created_at (str):
        owner (None | PublicOwnerType0):
    """

    slug: str
    name: str
    description: None | str
    visibility: PublicPersonaSummaryVisibility
    created_at: str
    owner: None | PublicOwnerType0
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.public_owner_type_0 import PublicOwnerType0

        slug = self.slug

        name = self.name

        description: None | str
        description = self.description

        visibility = self.visibility.value

        created_at = self.created_at

        owner: dict[str, Any] | None
        if isinstance(self.owner, PublicOwnerType0):
            owner = self.owner.to_dict()
        else:
            owner = self.owner

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "name": name,
                "description": description,
                "visibility": visibility,
                "createdAt": created_at,
                "owner": owner,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.public_owner_type_0 import PublicOwnerType0

        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        visibility = PublicPersonaSummaryVisibility(d.pop("visibility"))

        created_at = d.pop("createdAt")

        def _parse_owner(data: object) -> None | PublicOwnerType0:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_public_owner_type_0 = PublicOwnerType0.from_dict(data)

                return componentsschemas_public_owner_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | PublicOwnerType0, data)

        owner = _parse_owner(d.pop("owner"))

        public_persona_summary = cls(
            slug=slug,
            name=name,
            description=description,
            visibility=visibility,
            created_at=created_at,
            owner=owner,
        )

        public_persona_summary.additional_properties = d
        return public_persona_summary

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
