from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.support_grant import SupportGrant
    from ..models.support_read import SupportRead


T = TypeVar("T", bound="SupportLinkGrant")


@_attrs_define
class SupportLinkGrant:
    """
    Attributes:
        grant (SupportGrant):
        reads (list[SupportRead]): The latest 50 reads under the grant, newest first.
    """

    grant: SupportGrant
    reads: list[SupportRead]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        grant = self.grant.to_dict()

        reads = []
        for reads_item_data in self.reads:
            reads_item = reads_item_data.to_dict()
            reads.append(reads_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "grant": grant,
                "reads": reads,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.support_grant import SupportGrant
        from ..models.support_read import SupportRead

        d = dict(src_dict)
        grant = SupportGrant.from_dict(d.pop("grant"))

        reads = []
        _reads = d.pop("reads")
        for reads_item_data in _reads:
            reads_item = SupportRead.from_dict(reads_item_data)

            reads.append(reads_item)

        support_link_grant = cls(
            grant=grant,
            reads=reads,
        )

        support_link_grant.additional_properties = d
        return support_link_grant

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
