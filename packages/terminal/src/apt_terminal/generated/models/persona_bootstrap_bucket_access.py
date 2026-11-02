from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PersonaBootstrapBucketAccess")


@_attrs_define
class PersonaBootstrapBucketAccess:
    """A visitor token reports create/update/delete false whatever the underlying grant says.

    Attributes:
        read (bool):
        create (bool):
        update (bool):
        delete (bool):
    """

    read: bool
    create: bool
    update: bool
    delete: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        read = self.read

        create = self.create

        update = self.update

        delete = self.delete

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "read": read,
                "create": create,
                "update": update,
                "delete": delete,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        read = d.pop("read")

        create = d.pop("create")

        update = d.pop("update")

        delete = d.pop("delete")

        persona_bootstrap_bucket_access = cls(
            read=read,
            create=create,
            update=update,
            delete=delete,
        )

        persona_bootstrap_bucket_access.additional_properties = d
        return persona_bootstrap_bucket_access

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
