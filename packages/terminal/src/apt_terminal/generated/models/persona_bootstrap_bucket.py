from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.persona_bootstrap_bucket_scope import PersonaBootstrapBucketScope

if TYPE_CHECKING:
    from ..models.persona_bootstrap_bucket_access import PersonaBootstrapBucketAccess


T = TypeVar("T", bound="PersonaBootstrapBucket")


@_attrs_define
class PersonaBootstrapBucket:
    """A bucket the token can at least read. Unreadable buckets are omitted, not listed as denied.

    Attributes:
        id (str):
        name (str):
        kind (str):
        scope (PersonaBootstrapBucketScope):
        access (PersonaBootstrapBucketAccess): A visitor token reports create/update/delete false whatever the
            underlying grant says.
    """

    id: str
    name: str
    kind: str
    scope: PersonaBootstrapBucketScope
    access: PersonaBootstrapBucketAccess
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        name = self.name

        kind = self.kind

        scope = self.scope.value

        access = self.access.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "name": name,
                "kind": kind,
                "scope": scope,
                "access": access,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.persona_bootstrap_bucket_access import (
            PersonaBootstrapBucketAccess,
        )

        d = dict(src_dict)
        id = d.pop("id")

        name = d.pop("name")

        kind = d.pop("kind")

        scope = PersonaBootstrapBucketScope(d.pop("scope"))

        access = PersonaBootstrapBucketAccess.from_dict(d.pop("access"))

        persona_bootstrap_bucket = cls(
            id=id,
            name=name,
            kind=kind,
            scope=scope,
            access=access,
        )

        persona_bootstrap_bucket.additional_properties = d
        return persona_bootstrap_bucket

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
